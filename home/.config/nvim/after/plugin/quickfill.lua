local utils = require "core.utils"
utils.add_local_plugin(vim.fs.joinpath(vim.env.HOME, "projects", "quickfill.nvim"))

vim.keymap.set("i", "<C-q>", "<Plug>(quickfill-accept)")
vim.keymap.set("i", "<C-S-q>", "<Plug>(quickfill-accept-replace)")
vim.keymap.set("i", "<C-l>", "<Plug>(quickfill-accept-word)")
vim.keymap.set("i", "<C-space>", "<Plug>(quickfill-trigger)")

vim.g.quickfill = {
    url = "http://localhost:8012",
    model = "sweep-next-edit-0.5b.q8_0",
    n_predict = 16,
    chunk_lines = 8,
    max_extra_chunks = 2,
    n_suffix = 4,
    n_prefix = 4,
    max_lsp_completion_items = 10,
}
