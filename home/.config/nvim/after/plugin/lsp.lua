vim.pack.add { "https://github.com/neovim/nvim-lspconfig" }

local utils = require "core.utils"

vim.lsp.config("*", {
    capabilities = vim.lsp.protocol.make_client_capabilities(),
    flags = {
        debounce_text_changes = 2000,
        allow_incremental_sync = true,
    },
})

vim.lsp.config("angularls", {
    root_markers = { "angular.json", "nx.json", "Gruntfile.js" },
    cmd = utils.tbl_append(require("lspconfig.configs.angularls").default_config.cmd, "--forceStrictTemplates"),
    workspace_required = true,
})

vim.lsp.config("clangd", {
    cmd = {
        "clangd",
        "-j=3",
        "--header-insertion=iwyu",
        "--completion-style=detailed",
        "--cross-file-rename",
    },
    single_file_support = false,
    init_options = {
        clangdFileStatus = true,
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

vim.lsp.config("ocamllsp", {
    settings = {
        codelens = { enable = true },
        extendedHover = { enable = true },
        inlayHints = { enable = true },
        syntaxDocumentation = { enable = true },
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
}

local callbacks = {
    ts_ls = function(client, buffer)
        vim.keymap.set("n", "<leader>oi", function()
            local params = {
                command = "_typescript.organizeImports",
                arguments = { vim.api.nvim_buf_get_name(0) },
                title = "Organize Imports",
            }
            client:exec_cmd(params, { buffer = buffer })
        end, { buffer = buffer, desc = "Organize Imports" })
    end,
    clangd = function(_, buffer)
        vim.keymap.set("n", "<leader><tab>", vim.cmd.ClangdSwitchSourceHeader, { buffer = buffer })
    end,
}

local override_capabilities = {}

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("user.lspconfig", {}),
    callback = function(event)
        local client = assert(vim.lsp.get_client_by_id(event.data.client_id), "must have valid client")

        vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = event.buf })
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { buffer = event.buf })
        vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { buffer = event.buf })

        vim.opt_local.omnifunc = "v:lua.vim.lsp.omnifunc"
        if client.server_capabilities.definitionProvider then
            vim.opt_local.tagfunc = "v:lua.vim.lsp.tagfunc"
        end

        if client:supports_method(vim.lsp.protocol.Methods.textDocument_completion) then
            vim.lsp.completion.enable(true, client.id, event.buf, {
                convert = function(item)
                    local limit = vim.o.columns * 0.4
                    local label = item.label
                    if #label > limit then
                        label = label:sub(1, limit)
                        local last_comma = label:match ".*(),"
                        if last_comma then
                            label = label:sub(1, last_comma) .. " …)"
                        end
                    end
                    return {
                        abbr = label,
                        kind = item.kind and vim.lsp.protocol.CompletionItemKind[item.kind] or 1,
                        menu = item.detail and utils.shorten_path(item.detail, 15) or "",
                    }
                end,
            })
        end

        local callback = callbacks[client.name]
        if callback ~= nil then
            callback(client, event.buf)
        end

        client.server_capabilities.semanticTokensProvider = nil

        local capabilities = override_capabilities[client.name]
        if capabilities then
            for k, v in pairs(capabilities) do
                if v == vim.NIL then
                    v = nil
                end
                client.server_capabilities[k] = v
            end
        end
    end,
})
