vim.opt_local.iskeyword = vim.api.nvim_get_option_info2("iskeyword", {}).default

if vim.fn.executable "clang-format" and vim.fs.root(0, { ".clang-format" }) then
    vim.opt_local.formatprg = "clang-format -assume-filename %"
end
