local nbs = " "
local words = {
    "is",
    "it",
    "in",
    "of",
    "and",
    "or",
    "a",
    "the",
    "w",
    "oraz",
    "i",
    "do",
    "od",
    "na",
    "e.g.,",
    "as",
    "by",
    "to",
}

vim.api.nvim_create_user_command("Orphans", function()
    for _, word in pairs(words) do
        vim.cmd(string.format([[ silent %%s/\(\<%s\>\) /\1%s/ge ]], word, nbs))
    end
    vim.cmd(string.format([[ silent %%s/ \(\[.\{-}]\)/%s\1/ge ]], nbs))
end, {})
