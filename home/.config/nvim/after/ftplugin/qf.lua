vim.keymap.set("n", "<C-f>", function()
    vim.ui.input({ prompt = "filter> " }, function(pattern)
        if not pattern then
            return
        end

        local raw_patterns = vim.split(pattern, " ", { trimempty = true })
        local positives = {}
        local negatives = {}
        for _, p in ipairs(raw_patterns) do
            if p:sub(1, 1) == "!" then
                table.insert(negatives, p:sub(2))
            else
                table.insert(positives, p)
            end
        end

        local qflist = vim.fn.getqflist { id = 0, title = true, items = true }
        local filtered = {}

        local regex_pos = #positives > 0 and vim.regex(table.concat(positives, "|")) or nil
        local regex_neg = #negatives > 0 and vim.regex(table.concat(negatives, "|")) or nil

        for _, item in ipairs(qflist.items) do
            local bufname = vim.fn.bufname(item.bufnr)
            local text = item.text

            local matches_pos = regex_pos and (regex_pos:match_str(bufname) or regex_pos:match_str(text))
                or #positives == 0

            local matches_neg = regex_neg and (regex_neg:match_str(bufname) or regex_neg:match_str(text)) or false

            if matches_pos and not matches_neg then
                table.insert(filtered, item)
            end
        end

        vim.fn.setqflist({}, " ", { title = ("%s (%s)"):format(qflist.title, pattern), items = filtered, id = 0 })
    end)
end, { buffer = 0 })
