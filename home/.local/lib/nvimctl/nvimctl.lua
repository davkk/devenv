-- Worker terminals inside the host nvim. The bash CLI loads this file.
local M = {}
local uv = vim.uv or vim.loop

local function state_dir()
    local d = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/nvimctl/" .. vim.fn.fnamemodify(vim.v.servername, ":t")
    vim.fn.mkdir(d, "p")
    return d
end

local function marker(name, ext) return state_dir() .. "/" .. name .. "." .. ext end

local function find(name)
    if not name or name == "" then return nil end
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(b) and vim.b[b].nvimctl_name == name then return b end
    end
end

local function job_of(buf)
    if not buf or not vim.api.nvim_buf_is_valid(buf) then return nil end
    local job = vim.b[buf].terminal_job_id
    if not job or job <= 0 then return nil end
    if vim.fn.jobwait({ job }, 0)[1] ~= -1 then return nil end
    return job
end

local function worker(name)
    return find(name) or error("no worker '" .. tostring(name) .. "'", 0)
end

local function terminals()
    local out = {}
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[b].buftype == "terminal" then
            local t = vim.b[b].terminal_job_id
            if t then
                local ok, jp = pcall(vim.fn.jobpid, t)
                if ok and jp > 0 then out[#out + 1] = { b = b, jp = jp } end
            end
        end
    end
    return out
end

local function pid_set(pids)
    local set = {}
    for p in tostring(pids or ""):gmatch("%d+") do set[tonumber(p)] = true end
    return set
end

local function exe_of(pid)
    local ok, out = pcall(vim.fn.system, { "ps", "-o", "comm=", "-p", tostring(pid) })
    if not ok or not out then return nil end
    out = vim.trim(tostring(out))
    if out == "" then return nil end
    return vim.fn.fnamemodify(out, ":t")
end

-- Buffer of the terminal the caller runs in, shown or not.
local function caller_buffer(pids)
    local set = pid_set(pids)
    for _, tm in ipairs(terminals()) do
        if set[tm.jp] then return tm.b end
    end
end

-- Window of the caller's terminal: a shown terminal whose job pid is in the
-- caller's ancestry, else one whose ps command name matches the caller's exes.
local function caller_window(pids, exes)
    local terms = terminals()
    local function winof(b)
        local ws = vim.fn.win_findbuf(b)
        return (ws and ws[1]) or 0
    end
    for p in tostring(pids or ""):gmatch("%d+") do
        for _, tm in ipairs(terms) do
            if tm.jp == tonumber(p) then
                local w = winof(tm.b)
                if w > 0 then return w end
            end
        end
    end
    local eset = {}
    for e in tostring(exes or ""):gmatch("%S+") do eset[vim.fn.fnamemodify(e, ":t")] = true end
    for _, tm in ipairs(terms) do
        if not vim.b[tm.b].nvimctl_name then
            local e = exe_of(tm.jp)
            if e and eset[e] then
                local w = winof(tm.b)
                if w > 0 then return w end
            end
        end
    end
    return 0
end

function M.anchor_for(a) return tostring(caller_window(a[1], a[2])) end
function M.has_caller_terminal(a) return caller_buffer(a[1]) and "1" or "0" end

local shells = { sh = true, bash = true, dash = true, zsh = true, fish = true, ksh = true, ash = true }

local function is_shell(name)
    if not name then return false end
    local base = vim.fn.fnamemodify(tostring(name), ":t")
    return shells[base] == true
end

-- Readiness from one ps table, so this works on Linux and macOS.
local function proc_ready(root)
    local map, names = {}, {}
    local ok, out = pcall(vim.fn.system, { "ps", "-A", "-o", "pid=,ppid=,comm=" })
    if not ok or not out or out == "" then return nil end
    for line in tostring(out):gmatch("[^\n]+") do
        local p, pp, c = line:match("^%s*(%d+)%s+(%d+)%s+(%S+)")
        if p then
            p, pp = tonumber(p), tonumber(pp)
            names[p] = c
            map[pp] = map[pp] or {}
            table.insert(map[pp], p)
        end
    end
    local seen, found = {}, false
    local function visit(pid)
        if not pid or pid <= 0 or seen[pid] then return end
        seen[pid] = true
        local name = names[pid]
        if name and not is_shell(name) then found = true; return end
        for _, c in ipairs(map[pid] or {}) do
            visit(c)
            if found then return end
        end
    end
    if root and root > 0 then visit(root) end
    return found
end

function M.ready(a)
    local job = job_of(find(a[1]))
    if not job then return "0" end
    local ok, jp = pcall(vim.fn.jobpid, job)
    if not ok or not jp or jp <= 0 then return "?" end
    local r = proc_ready(jp)
    if r == nil then return "?" end
    return r == true and "1" or "0"
end

local function live_count()
    local n = 0
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.b[b].nvimctl_name and job_of(b) then n = n + 1 end
    end
    return n
end

-- Rightmost window in a tab, matching the old `botright vnew` placement
-- without entering the new window.
local function rightmost_window(tab)
    local best, bestcol = 0, -1
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
        local cfg = vim.api.nvim_win_get_config(w)
        if cfg.relative == "" then
            local col = vim.api.nvim_win_get_position(w)[2]
            if col > bestcol then best, bestcol = w, col end
        end
    end
    return best
end

-- spawn CWD PIDS EXES NAME LAYOUT MAX CMD...
function M.spawn(a)
    local cwd, pids, exes, name = a[1], a[2], a[3], a[4]
    local layout, max = a[5], tonumber(a[6]) or 2
    local argv = vim.list_slice(a, 7)
    if #argv == 0 then error("spawn needs a command", 0) end

    local old = find(name)
    if old then
        if job_of(old) then error("worker '" .. name .. "' is already running", 0) end
        pcall(vim.api.nvim_buf_delete, old, { force = true })
    end
    if live_count() >= max then
        error(("%d workers already running (NVIMCTL_MAX=%d); reuse one or stop one"):format(live_count(), max), 0)
    end
    for _, ext in ipairs({ "busy", "done", "exit", "result" }) do os.remove(marker(name, ext)) end

    local cbuf = caller_buffer(pids)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "hide"
    vim.b[buf].nvimctl = vim.fn.fnamemodify(argv[1], ":t")
    vim.b[buf].nvimctl_name = name
    vim.b[buf].nvimctl_parent = cbuf and vim.b[cbuf].nvimctl_name or nil

    local win
    if layout ~= "hidden" then
        local anchor = caller_window(pids, exes)
        if anchor <= 0 or not vim.api.nvim_win_is_valid(anchor) then anchor = vim.api.nvim_get_current_win() end
        local target = rightmost_window(vim.api.nvim_win_get_tabpage(anchor))
        if target == 0 then target = anchor end
        local ok, w = pcall(vim.api.nvim_open_win, buf, false, { split = "right", win = target })
        if ok then win = w end
    end

    local env = { NVIMCTL_NAME = name }
    if vim.v.servername ~= "" then env.NVIM = vim.v.servername end
    local opts = {
        term = true,
        cwd = cwd,
        env = env,
        on_exit = function(_, code)
            if find(name) ~= buf then return end
            local f = io.open(marker(name, "exit"), "w")
            if f then f:write(tostring(code)); f:close() end
            os.remove(marker(name, "busy"))
        end,
    }
    local ok, job = pcall(vim.api.nvim_buf_call, buf, function() return vim.fn.jobstart(argv, opts) end)
    if not ok or not job or job <= 0 then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
        error("cannot start: " .. table.concat(argv, " "), 0)
    end
    if win then pcall(vim.api.nvim_win_set_cursor, win, { vim.api.nvim_buf_line_count(buf), 0 }) end
    return tostring(buf)
end

function M.send(a)
    local job = job_of(worker(a[1])) or error("worker '" .. a[1] .. "' is not running", 0)
    local text = a[2] or ""
    if text ~= "" and vim.fn.chansend(job, text) <= 0 then
        error("worker '" .. a[1] .. "' is not accepting input", 0)
    end
    return ""
end

function M.read(a)
    local lines = vim.api.nvim_buf_get_lines(worker(a[1]), 0, -1, false)
    while #lines > 0 and lines[#lines]:match("^%s*$") do table.remove(lines) end
    return table.concat(lines, "\n")
end

function M.stop(a)
    pcall(vim.api.nvim_buf_delete, worker(a[1]), { force = true })
    return "stopped"
end

function M.alive(a) return job_of(find(a[1])) and "1" or "0" end

function M.cli(a)
    local cmd = table.remove(a, 1)
    local handler = M[cmd]
    if type(handler) ~= "function" or cmd == "cli" then return "nvimctl: unknown command " .. tostring(cmd) end
    local ok, res = pcall(handler, a)
    return ok and tostring(res) or ("nvimctl: " .. tostring(res))
end

return M
