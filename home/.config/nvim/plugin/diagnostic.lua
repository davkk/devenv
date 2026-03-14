vim.diagnostic.config {
    severity_sort = true,
    virtual_text = true,
    underline = true,
    update_in_insert = false,
    float = {
        source = true,
        show_header = true,
        style = "minimal",
        header = "",
        prefix = "",
        border = "solid",
    },
}

vim.api.nvim_create_user_command("ToggleDiagnostics", function()
    vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, {})
