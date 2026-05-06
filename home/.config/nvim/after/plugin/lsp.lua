vim.pack.add { "https://github.com/neovim/nvim-lspconfig" }

vim.lsp.config("*", {
    capabilities = vim.lsp.protocol.make_client_capabilities(),
    flags = {
        debounce_text_changes = 2000,
        allow_incremental_sync = true,
    },
})

vim.lsp.config("lua_ls", {
    settings = {
        Lua = {
            runtime = {
                version = "LuaJIT",
            },
            diagnostics = {
                globals = { "vim" },
                disable = { "missing-fields" },
            },
            workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
                checkThirdParty = false,
            },
            telemetry = { enable = false },
        },
    },
})

vim.lsp.config("zls", {
    settings = {
        zls = {
            enable_build_on_save = true,
        },
    },
})

vim.lsp.config("basedpyright", {
    settings = {
        basedpyright = {
            analysis = {
                typeCheckingMode = "basic",
                diagnosticMode = "workspace",
            },
        },
    },
})

vim.lsp.enable {
    "lua_ls",
    "ts_ls",
    "jsonls",
    "cssls",
    "clangd",
    "ocamllsp",
    "basedpyright",
    "ruff",
    "gopls",
    "zls",
    "tinymist",
    "jdtls",
}

local group = vim.api.nvim_create_augroup("user.lsp", {})

vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(event)
        local client = assert(vim.lsp.get_client_by_id(event.data.client_id), "must have valid client")
        client.server_capabilities.semanticTokensProvider = nil
    end,
})

vim.api.nvim_create_autocmd("LspProgress", {
    group = group,
    callback = function(ev)
        local value = ev.data.params.value or {}
        local msg = value.message or "done"
        if #msg > 40 then
            msg = msg:sub(1, 37) .. "..."
        end
        vim.api.nvim_echo({ { msg } }, false, {
            id = "lsp",
            source = "lsp",
            kind = "progress",
            title = value.title,
            status = value.kind ~= "end" and "running" or "success",
            percent = value.percentage,
        })
    end,
})

vim.diagnostic.config {
    severity_sort = true,
    virtual_text = true,
    float = {
        source = true,
        show_header = true,
        header = "",
        prefix = "",
    },
}
