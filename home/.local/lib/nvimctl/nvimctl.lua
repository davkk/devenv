-- Terminal splits inside the host nvim, driven by the `nvimctl` CLI.
--
-- Transport only: spawn a command in a split, send bytes, read the screen,
-- close the split. The worker turn protocol (task, done, wait) lives in the
-- CLI.

local M = {}

local state_dir = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/nvimctl"

vim.fn.mkdir(state_dir, "p")

local function marker(buf) return state_dir .. "/" .. buf end

local function fexists(path)
    local uv = vim.uv or vim.loop
    return uv.fs_stat(path) ~= nil
end

local function clear_state(buf)
    os.remove(marker(buf) .. ".done")
    os.remove(marker(buf) .. ".busy")
    os.remove(marker(buf) .. ".exit")
    os.remove(marker(buf) .. ".protocol")
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

local function open_split(argv, cwd, name)
    local origin = vim.api.nvim_get_current_win()
    vim.cmd("botright vnew")
    local buf = vim.api.nvim_get_current_buf()
    vim.b[buf].nvimctl = vim.fn.fnamemodify(argv[1] or "worker", ":t")
    if name and name ~= "" then vim.b[buf].nvimctl_name = name end
    clear_state(buf)
    local job_opts = {
        term = true,
        cwd = cwd,
        on_exit = function(_, code)
            local f = io.open(marker(buf) .. ".exit", "w")
            if f then f:write(code); f:close() end
            os.remove(marker(buf) .. ".busy")
        end,
    }
    -- Give the child the host socket so its own nvimctl calls drive this
    -- instance even when it did not inherit $NVIM.
    local sock = vim.v.servername
    if sock ~= "" then job_opts.env = { NVIM = sock } end
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

-- Generic readiness. Walk the process tree rooted at the terminal's job pid.
-- The terminal starts in a shell; the spawned command (or anything it execs)
-- is a non-shell process in that tree. Ready means such a process exists, so
-- the CLI never types a task into a bare shell prompt. No harness strings.
local shells = { sh = true, bash = true, dash = true, zsh = true, fish = true, ksh = true, ash = true }

local function is_shell(name)
    if not name then return false end
    local base = tostring(name):gsub("%s+$", ""):match("([^/]+)$") or tostring(name)
    return shells[base] == true
end

-- true: a non-shell process is running; false: only shells (not ready);
-- nil: process inspection is unavailable, fall back to the screen in the CLI.
local function proc_ready(root)
    local uv = vim.uv or vim.loop
    local inspected, found = false, false
    local children_of, name_of

    if uv.fs_stat("/proc") then
        children_of = function(pid)
            local f = io.open("/proc/" .. pid .. "/task/" .. pid .. "/children", "r")
            if not f then return {} end
            local s = f:read("*a")
            f:close()
            local out = {}
            for n in tostring(s or ""):gmatch("%d+") do out[#out + 1] = tonumber(n) end
            return out
        end
        name_of = function(pid)
            local e = uv.fs_readlink("/proc/" .. pid .. "/exe")
            if e and e ~= "" then inspected = true; return e end
            local f = io.open("/proc/" .. pid .. "/comm", "r")
            if f then
                local s = f:read("*a")
                f:close()
                if s and s ~= "" then inspected = true; return s end
            end
            return nil
        end
    else
        -- macOS and other systems without /proc: build the tree from ps.
        local map, names = {}, {}
        local ok, out = pcall(vim.fn.system, { "ps", "-A", "-o", "pid=,ppid=,comm=" })
        if ok and out and out ~= "" then
            for line in tostring(out):gmatch("[^\n]+") do
                local p, pp, c = line:match("^%s*(%d+)%s+(%d+)%s+(%S+)")
                if p then
                    p, pp = tonumber(p), tonumber(pp)
                    names[p] = c
                    map[pp] = map[pp] or {}
                    table.insert(map[pp], p)
                    inspected = true
                end
            end
        end
        children_of = function(pid) return map[pid] or {} end
        name_of = function(pid) return names[pid] end
    end

    local seen = {}
    local function visit(pid)
        if not pid or pid <= 0 or seen[pid] then return end
        seen[pid] = true
        local name = name_of(pid)
        if name and not is_shell(name) then found = true; return end
        for _, c in ipairs(children_of(pid)) do
            visit(c)
            if found then return end
        end
    end
    if root and root > 0 then visit(root) end
    if found then return true end
    if not inspected then return nil end
    return false
end

-- ready BUF -> "1" ready, "0" still a shell, "?" inspection unavailable.
function M.ready(a)
    local job = job_of(tonumber(a[1]))
    if not job then return "0" end
    local ok, jp = pcall(vim.fn.jobpid, job)
    if not ok or not jp or jp <= 0 then return "?" end
    local r = proc_ready(jp)
    if r == true then return "1" end
    if r == nil then return "?" end
    return "0"
end

-- spawn CWD PIDS EXES NAME CMD... -- the split always goes in the caller's own window.
function M.spawn(a)
    local cwd, pids, exes = a[1], a[2], a[3]
    local name = a[4]
    if name == "" then name = nil end
    local argv = vim.list_slice(a, 5)
    if #argv == 0 then return "usage: nvimctl spawn CMD..." end

    local anchor = caller_window(pids, exes)
    if anchor > 0 and vim.api.nvim_win_is_valid(anchor) then
        local ok, res = pcall(vim.api.nvim_win_call, anchor, function()
            return open_split(argv, cwd, name)
        end)
        return ok and tostring(res) or ("window " .. anchor .. " refused the split: " .. tostring(res))
    end
    return tostring(open_split(argv, cwd, name))
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

local function state_of(buf)
    if fexists(marker(buf) .. ".done") then return "done" end
    if fexists(marker(buf) .. ".exit") then return "exit" end
    if fexists(marker(buf) .. ".busy") then return "busy" end
    if job_of(buf) then return "ready" end
    return "exit"
end

function M.list()
    local rows = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local cmd = vim.b[buf].nvimctl
        if cmd then
            local name = vim.b[buf].nvimctl_name or "-"
            rows[#rows + 1] = string.format("%s\t%d\t%s\t%s", name, buf, cmd, state_of(buf))
        end
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
