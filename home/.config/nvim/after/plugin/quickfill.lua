local utils = require "core.utils"
utils.add_local_plugin(vim.fs.joinpath(vim.env.HOME, "projects", "quickfill.nvim"))

vim.keymap.set("i", "<C-q>", "<Plug>(quickfill-accept)")
vim.keymap.set("i", "<C-S-q>", "<Plug>(quickfill-accept-replace)")
vim.keymap.set("i", "<C-l>", "<Plug>(quickfill-accept-word)")
vim.keymap.set("i", "<C-space>", "<Plug>(quickfill-trigger)")

---@type quickfill.Config
vim.g.quickfill = {
    url = "http://localhost:8012",
    model = "sweep-next-edit-1.5b.q8_0.v2",
    chunk_lines = 4,
    max_extra_chunks = 3,
    n_suffix = 8,
    n_prefix = 8,
    max_lsp_completion_items = 10,
    fresh_on_trigger_char = false,
}
