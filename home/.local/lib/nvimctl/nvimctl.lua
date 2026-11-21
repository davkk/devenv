-- Terminal splits inside the host nvim, driven by the `nvimctl` CLI.
--
-- Transport only: spawn a command in a split, send bytes, read the screen,
-- close the split. The worker turn protocol (task, done, wait) lives in the
-- CLI.

local M = {}

local state_dir = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/nvimctl"

vim.fn.mkdir(state_dir, "p")

local function marker(buf) return state_dir .. "/" .. buf end

local function clear_state(buf)
    os.remove(marker(buf) .. ".done")
    os.remove(marker(buf) .. ".busy")
    os.remove(marker(buf) .. ".exit")
end

local function job_of(buf)
    if not buf or not vim.api.nvim_buf_is_valid(buf) then return nil end
    local job = vim.b[buf].terminal_job_id
    if job and job > 0 then return job end
end

local function send(buf, text)
    local job = job_of(buf) or error("buffer " .. tostring(buf) .. " is not a live terminal", 0)
    if vim.fn.chansend(job, text) <= 0 then
        error("buffer " .. tostring(buf) .. " is not accepting input", 0)
    end
end

-- Leave terminal-insert mode and park the cursor on the last line.
local function unfocus()
    pcall(vim.cmd, "stopinsert")
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-N>", true, false, true), "n", false)
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_get_current_buf()
    pcall(vim.api.nvim_win_set_cursor, win, { vim.api.nvim_buf_line_count(buf), 0 })
end

local function open_split(argv, cwd, anchor)
    local origin = vim.api.nvim_get_current_win()
    vim.cmd("botright vnew")
    local buf = vim.api.nvim_get_current_buf()
    vim.b[buf].nvimctl = vim.fn.fnamemodify(argv[1] or "worker", ":t")
    clear_state(buf)
    -- Children inherit the anchor so their own spawns stay in this window
    -- even after the user switches tabs. An explicit NVIMCTL_WIN in a child
    -- still wins over the inherited value.
    local job_env = {}
    if anchor and anchor > 0 and vim.api.nvim_win_is_valid(anchor) then
        job_env.NVIMCTL_WIN = tostring(anchor)
        -- Also pass the host instance's socket, so the child drives the
        -- right one even without an inherited $NVIM.
        local sock = vim.v.servername
        if sock ~= "" then job_env.NVIM = sock end
    end
    local job_opts = {
        term = true,
        cwd = cwd,
        on_exit = function(_, code)
            local f = io.open(marker(buf) .. ".exit", "w")
            if f then f:write(code); f:close() end
            os.remove(marker(buf) .. ".busy")
        end,
    }
    -- An empty env table clears the child's whole environment, so only set
    -- it when there is something to pass down (an anchor, or the host socket).
    if next(job_env) then job_opts.env = job_env end
    local job = vim.fn.jobstart(argv, job_opts)
    if job <= 0 then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
        return "cannot start: " .. table.concat(argv, " ")
    end
    vim.bo[buf].bufhidden = "wipe"
    unfocus()
    pcall(vim.api.nvim_set_current_win, origin)
    return buf
end

-- Find the window the caller is running in: a terminal whose job pid is in
-- the caller's process ancestry, else one running one of its executables.
-- Returns 0 when nothing matches, so spawn falls back to the current window.
local function caller_window(pids, exes)
    local chain = {}
    for p in tostring(pids or ""):gmatch("%d+") do chain[#chain + 1] = tonumber(p) end
    local eset = {}
    for e in tostring(exes or ""):gmatch("%S+") do eset[e] = true end

    local terms = {}
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[b].buftype == "terminal" then
            local t = vim.b[b].terminal_job_id
            if t then
                local ok, jp = pcall(vim.fn.jobpid, t)
                if ok then terms[#terms + 1] = { b = b, jp = jp } end
            end
        end
    end
    local function winof(b)
        local ws = vim.fn.win_findbuf(b)
        return (ws and ws[1]) or 0
    end
    for _, cp in ipairs(chain) do
        for _, tm in ipairs(terms) do
            if tm.jp == cp then
                local w = winof(tm.b)
                if w > 0 then return w end
            end
        end
    end
    local uv = vim.uv or vim.loop
    for _, tm in ipairs(terms) do
        if not vim.b[tm.b].nvimctl then
            local e = uv.fs_readlink("/proc/" .. tm.jp .. "/exe")
            if e and eset[e] then
                local w = winof(tm.b)
                if w > 0 then return w end
            end
        end
    end
    return 0
end

-- Window id of the caller's terminal in this instance, or 0: the caller's
-- process ancestry tells which terminal job it is running in. Used by the
-- bash driver to find the instance that hosts the caller.
function M.anchor_for(a) return tostring(caller_window(a[1] or "", a[2] or "")) end

-- True when the caller's ancestry runs a terminal job in this instance, even
-- when the caller's window is not here (e.g. $NVIM names the wrong socket).
function M.has_caller_terminal(a)
    local chain = {}
    for p in tostring(a[1] or ""):gmatch("%d+") do chain[#chain + 1] = tonumber(p) end
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[b].buftype == "terminal" then
            local t = vim.b[b].terminal_job_id
            if t then
                local ok, jp = pcall(vim.fn.jobpid, t)
                if ok and jp > 0 and vim.tbl_contains(chain, jp) then return "1" end
            end
        end
    end
    return "0"
end

-- Is this window id a window in this instance? (a wrong-socket check)
function M.winflag(a)
    local w = tonumber(a[1]) or 0
    return w > 0 and vim.api.nvim_win_is_valid(w) and "1" or "0"
end

-- spawn CWD WIN PIDS EXES CMD... -- WIN 0 means autodetect the caller's window.
function M.spawn(a)
    local cwd, win, pids, exes = a[1], tonumber(a[2]) or 0, a[3], a[4]
    local argv = vim.list_slice(a, 5)
    if #argv == 0 then return "usage: nvimctl spawn CMD..." end

    local anchor = win
    if anchor <= 0 or not vim.api.nvim_win_is_valid(anchor) then
        anchor = caller_window(pids, exes)
    end
    if anchor > 0 and vim.api.nvim_win_is_valid(anchor) then
        local ok, res = pcall(vim.api.nvim_win_call, anchor, function()
            return open_split(argv, cwd, anchor)
        end)
        return ok and tostring(res) or ("window " .. anchor .. " refused the split: " .. tostring(res))
    end
    return tostring(open_split(argv, cwd, 0))
end

-- send BUF TEXT -- raw bytes; the caller supplies CR, LF, or control codes.
function M.send(a)
    local buf = tonumber(a[1])
    local text = a[2] or ""
    if not buf then return "usage: nvimctl send BUF TEXT..." end
    if text == "" then return "" end
    local ok, err = pcall(send, buf, text)
    return ok and "" or tostring(err)
end

function M.read(a)
    local buf = tonumber(a[1])
    if not buf or not vim.api.nvim_buf_is_valid(buf) then return "no buffer " .. tostring(a[1]) end
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    while #lines > 0 and lines[#lines]:match("^%s*$") do table.remove(lines) end
    return table.concat(lines, "\n")
end

function M.stop(a)
    local buf = tonumber(a[1])
    if not buf then return "usage: nvimctl stop BUF" end
    pcall(vim.cmd, "bwipeout! " .. buf)
    clear_state(buf)
    return "stopped"
end

function M.list()
    local rows = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.b[buf].nvimctl
        if name then rows[#rows + 1] = string.format("%d\t%s\t%s", buf, name, job_of(buf) and "live" or "dead") end
    end
    return #rows > 0 and table.concat(rows, "\n") or "no workers"
end

function M.alive(a) return job_of(tonumber(a[1])) and "1" or "0" end

function M.cli(a)
    local cmd = table.remove(a, 1)
    local handler = M[cmd]
    if type(handler) ~= "function" or cmd == "cli" then return "unknown command " .. tostring(cmd) end
    local ok, res = pcall(handler, a)
    return ok and tostring(res) or ("nvimctl: " .. tostring(res))
end

return M
