local function parse_output(out)
    local lines = vim.split(out, "\n")
    if lines[#lines] == "" then
        table.remove(lines)
    end
    return lines
end

local function new_buffer(name, lines)
    local buf = vim.api.nvim_create_buf(false, true)
    if name then
        vim.api.nvim_buf_set_name(buf, "diff://" .. name:gsub("/$", ""))
    end
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].filetype = vim.bo.filetype ~= "" and vim.bo.filetype or "git"
    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
end

local function git_context()
    local root = vim.fs.root(0, ".git")
    if not root then
        vim.notify("Not in a git repository", vim.log.levels.ERROR)
        return
    end
    local fullpath = vim.fn.expand "%:p"
    if fullpath == "" then
        vim.notify("No file under cursor", vim.log.levels.ERROR)
        return
    end
    return root, fullpath, fullpath:sub(#root + 2)
end

local function git_diff(ref)
    ref = ref or "HEAD"
    local root, fullpath, relpath = git_context()
    if not root then
        return
    end

    local lstree = vim.system({ "git", "ls-tree", ref, "--", relpath }, { cwd = root }):wait()
    if lstree.code ~= 0 then
        return vim.notify(("ls-tree failed for %s"):format(relpath), vim.log.levels.ERROR)
    end

    local lsfiles = vim.system({ "git", "ls-files", "--stage", "--", relpath }, { cwd = root }):wait()
    if lsfiles.code ~= 0 then
        return vim.notify(("ls-files failed for %s"):format(relpath), vim.log.levels.ERROR)
    end

    if lstree.stdout:match "^160000" or lsfiles.stdout:match "^160000" then
        local old_hash = lstree.stdout:match "commit%s+([0-9a-fA-F]+)"
        local cmd = (old_hash and lsfiles.stdout ~= "") and { "git", "diff", old_hash }
            or { "git", "diff", ref, "--", relpath }
        new_buffer(fullpath, parse_output(vim.system(cmd, { cwd = root }):wait().stdout))
        return
    end

    local lines_ref = {}
    if lstree.stdout ~= "" then
        local show = vim.system({ "git", "show", ("%s:%s"):format(ref, relpath) }, { cwd = root }):wait()
        if show.code ~= 0 then
            return vim.notify(("show failed for %s: %s"):format(relpath, show.stderr), vim.log.levels.ERROR)
        end
        lines_ref = parse_output(show.stdout)
    end

    vim.cmd.vsplit { mods = { split = "leftabove" } }
    new_buffer(fullpath, lines_ref)
    vim.cmd.diffthis()
    vim.cmd.wincmd "p"
    vim.cmd.diffthis()
end

local function git_blame(ref)
    local root, _, relpath = git_context()
    if not root then
        return
    end

    local row = unpack(vim.api.nvim_win_get_cursor(0))
    local args = { "git", "blame" }
    if ref then
        args[#args + 1] = ref
    end
    vim.list_extend(args, { ("-L%d,%d"):format(row, row), "--", relpath })

    local res = vim.system(args, { cwd = root }):wait()
    if res.code ~= 0 then
        return vim.notify(("blame failed for %s"):format(relpath), vim.log.levels.ERROR)
    end
    print(res.stdout)
end

vim.api.nvim_create_user_command("GitDiff", function(cmd)
    git_diff(cmd.fargs[1])
end, { nargs = "*" })

vim.api.nvim_create_user_command("GitBlame", function(cmd)
    git_blame(cmd.fargs[1])
end, { nargs = "*" })

local opts = { noremap = true, silent = true }

vim.keymap.set({ "n", "v" }, "gh", ":diffget LOCAL<cr>", opts)
vim.keymap.set({ "n", "v" }, "gl", ":diffget REMOTE<cr>", opts)

vim.keymap.set("n", "<leader>gd", git_diff, opts)
vim.keymap.set("n", "<leader>gD", function()
    local ref = vim.fn.input "ref> "
    git_diff(ref)
end, opts)

vim.keymap.set("n", "<leader>gB", function()
    local ref = vim.fn.input "ref> "
    git_blame(ref)
end, opts)
vim.keymap.set("n", "<leader>gb", git_blame, opts)
