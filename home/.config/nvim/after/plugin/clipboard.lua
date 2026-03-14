local function paste(_)
    return function(_)
        local content = vim.fn.getreg '"'
        return vim.split(content, "\n")
    end
end
if os.getenv "SSH_CLIENT" ~= nil or os.getenv "SSH_TTY" ~= nil then
    local osc52 = require "vim.ui.clipboard.osc52"
    vim.g.clipboard = {
        name = "OSC 52",
        copy = {
            ["+"] = osc52.copy "+",
            ["*"] = osc52.copy "*",
        },
        paste = {
            ["+"] = paste "+",
            ["*"] = paste "*",
        },
    }
end
