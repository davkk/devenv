vim.opt_local.iskeyword = vim.api.nvim_get_option_info2("iskeyword", {}).default
vim.opt_local.formatprg = "clang-format -assume-filename %"
