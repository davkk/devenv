local lint = require "core.lint"
local utils = require "core.utils"

lint.config("cpplint", {
    cmd = { "cpplint", "--quiet", utils.relative_path },
    pattern = { "*.c", "*.C", "*.cxx", "*.cpp", "*.h", "*.hpp" },
    stream = "stderr",
    parser = function(bufnr, output)
        local diagnostics = {}
        for _, line in ipairs(vim.split(output, "\n")) do
            local lnum, message, code = string.match(line, "[^:]+:(%d+):  (.+)  (.+)")
            if lnum and message then
                lnum = tonumber(lnum) or 1
                local content = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
                local indent = string.find(content, "%S")
                table.insert(diagnostics, {
                    lnum = tonumber(lnum) - 1,
                    col = (indent or 1) - 1,
                    end_col = #content,
                    message = message,
                    source = "cpplint",
                    severity = vim.diagnostic.severity.INFO,
                    code = code,
                })
            end
        end
        return diagnostics
    end,
    root_markers = function(name)
        return name:match "^.cpplint"
    end,
})

lint.config("eslint_d", {
    cmd = { "eslint_d", "--format=json", utils.relative_path },
    pattern = { "*.ts", "*.js", "*.jsx", "*.tsx" },
    parser = function(_, output)
        local decode_opts = { luanil = { object = true, array = true } }
        local ok, data = pcall(vim.json.decode, output, decode_opts)
        if not ok then
            return {}
        end

        local severities = {
            vim.diagnostic.severity.WARN,
            vim.diagnostic.severity.ERROR,
        }

        ---@type vim.Diagnostic[]
        local diagnostics = {}
        for _, result in ipairs(data or {}) do
            for _, msg in ipairs(result.messages or {}) do
                table.insert(diagnostics, {
                    lnum = msg.line and (msg.line - 1) or 0,
                    end_lnum = msg.endLine and (msg.endLine - 1) or nil,
                    col = msg.column and (msg.column - 1) or 0,
                    end_col = msg.endColumn and (msg.endColumn - 1) or nil,
                    message = msg.message,
                    code = msg.ruleId,
                    severity = severities[msg.severity],
                    source = "eslint_d",
                })
            end
        end

        return diagnostics
    end,
    root_markers = function(name)
        return name:match "^.eslintrc" or name:match "^eslint.config"
    end,
})

lint.config("flake8", {
    cmd = { "flake8", utils.relative_path },
    pattern = { "*.py" },
    parser = function(bufnr, output)
        local severity = {
            F = vim.diagnostic.severity.INFO,
            E = vim.diagnostic.severity.ERROR,
            W = vim.diagnostic.severity.WARN,
        }

        local diagnostics = {}
        for _, line in ipairs(vim.split(output, "\n")) do
            local lnum, col, code, message = string.match(line, "[^:]+:(%d+):(%d+): (%w+) (.+)")
            if lnum and col and code and message then
                lnum = tonumber(lnum) or 1
                col = tonumber(col) or 1
                local content = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
                local indent = string.find(content, "%S")
                table.insert(diagnostics, {
                    lnum = tonumber(lnum) - 1,
                    col = (indent or 1) - 1,
                    end_col = #content,
                    message = message,
                    source = "flake8",
                    severity = severity[code:sub(1, 1)] or vim.diagnostic.severity.INFO,
                    code = code,
                })
            end
        end

        return diagnostics
    end,
    root_markers = { ".flake8", ".flake8.ini" },
})

lint.enable {
    "cpplint",
    "eslint_d",
    "flake8",
}
