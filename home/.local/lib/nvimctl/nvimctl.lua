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

local function open_split(argv, cwd)
    local origin = vim.api.nvim_get_current_win()
    vim.cmd("botright vnew")
    local buf = vim.api.nvim_get_current_buf()
    vim.b[buf].nvimctl = vim.fn.fnamemodify(argv[1] or "worker", ":t")
    clear_state(buf)
    local job = vim.fn.jobstart(argv, {
        term = true,
        cwd = cwd,
        on_exit = function(_, code)
            local f = io.open(marker(buf) .. ".exit", "w")
            if f then f:write(code); f:close() end
            os.remove(marker(buf) .. ".busy")
        end,
    })
    if job <= 0 then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
        return "cannot start: " .. table.concat(argv, " ")
    end
    vim.bo[buf].bufhidden = "wipe"
    unfocus()
    pcall(vim.api.nvim_set_current_win, origin)
    return buf
end

-- spawn CWD WIN CMD... -- WIN 0 means the current window.
function M.spawn(a)
    local cwd, win, argv = a[1], tonumber(a[2]) or 0, vim.list_slice(a, 3)
    if #argv == 0 then return "usage: nvimctl spawn CMD..." end
    if win > 0 and vim.api.nvim_win_is_valid(win) then
        local ok, res = pcall(vim.api.nvim_win_call, win, function() return open_split(argv, cwd) end)
        return ok and tostring(res) or ("window " .. win .. " refused the split: " .. tostring(res))
    end
    return tostring(open_split(argv, cwd))
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
