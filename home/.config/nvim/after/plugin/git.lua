---@param name string
---@param lines string[]
local function new_buffer(name, lines)
    local buf = vim.api.nvim_create_buf(false, true)
    if name then
        name = name:gsub("/$", "")
        vim.api.nvim_buf_set_name(buf, "diff://" .. name)
    end
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].filetype = vim.bo.filetype == "" and "git" or vim.bo.filetype
    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
end

---@param output string
local function parse_output(output)
    local lines = vim.split(output, "\n")
    if #lines > 0 and lines[#lines] == "" then
        table.remove(lines)
    end
    return lines
end

---@param ref string | nil
local function git_diff(ref)
    ref = ref or "HEAD"

    local root_dir = vim.fs.root(0, ".git")
    if not root_dir then
        vim.notify("Not in a git repository", vim.log.levels.ERROR)
        return
    end

    local fullpath = vim.fn.expand "%:p"
    if fullpath == "" then
        vim.notify("No file under cursor", vim.log.levels.ERROR)
        return
    end

    local relpath = fullpath:sub(#root_dir + 2)

    local lstree_res = vim.system({ "git", "ls-tree", ref, "--", relpath }, { cwd = root_dir }):wait()
    if lstree_res.code ~= 0 then
        vim.notify(("ls-tree failed for %s"):format(relpath), vim.log.levels.ERROR)
        return
    end

    local lsfiles_res = vim.system({ "git", "ls-files", "--stage", "--", relpath }, { cwd = root_dir }):wait()
    if lsfiles_res.code ~= 0 then
        vim.notify(("ls-files failed for %s"):format(relpath), vim.log.levels.ERROR)
        return
    end

    local file_exists_ref = lstree_res.stdout ~= ""
    local file_exists_head = lsfiles_res.stdout ~= ""

    local is_submodule = lstree_res.stdout:match "^160000" or lsfiles_res.stdout:match "^160000"
    if is_submodule then
        local old_hash = string.match(lstree_res.stdout, "commit%s+([0-9a-fA-F]+)")

        local diff_res
        if old_hash ~= nil and file_exists_head then
            diff_res = vim.system({ "git", "diff", old_hash }, { cwd = root_dir }):wait()
        else
            diff_res = vim.system({ "git", "diff", ref, "--", relpath }, { cwd = root_dir }):wait()
        end

        new_buffer(fullpath, parse_output(diff_res.stdout))
        return
    end

    local lines_ref = {}
    if file_exists_ref then
        local show_res = vim.system({ "git", "show", ("%s:%s"):format(ref, relpath) }, { cwd = root_dir }):wait()
        if show_res.code ~= 0 then
            vim.notify(("show failed for %s: %s"):format(relpath, show_res.stderr), vim.log.levels.ERROR)
            return
        end
        lines_ref = parse_output(show_res.stdout)
    end

    vim.cmd [[leftabove vsplit]]

    new_buffer(fullpath, lines_ref)

    vim.cmd.diffthis()
    vim.cmd.wincmd "p"
    vim.cmd.diffthis()
end

vim.api.nvim_create_user_command("GitDiff", function(cmd)
    git_diff(cmd.fargs[1])
end, { nargs = "*", desc = "Diff current buffer with given Git ref" })

local opts = { noremap = true, silent = true }

vim.keymap.set("n", "<leader>gd", git_diff, opts)
vim.keymap.set("n", "<leader>gD", function()
    local ref = vim.fn.input "ref> "
    git_diff(ref)
end, opts)

vim.keymap.set({ "n", "v" }, "gh", ":diffget LOCAL<cr>", opts)
vim.keymap.set({ "n", "v" }, "gl", ":diffget REMOTE<cr>", opts)
