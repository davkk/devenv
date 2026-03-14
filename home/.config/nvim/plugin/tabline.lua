Tabline = {}

local function get_tabs()
    local tabs = {}
    local pos = 1

    for idx = 1, vim.fn.tabpagenr "$" do
        local winnr = vim.fn.tabpagewinnr(idx)
        local buflist = vim.fn.tabpagebuflist(idx)
        local bufnr = buflist[winnr]
        local bufname = vim.fn.bufname(bufnr)

        if bufname == "" then
            bufname = "No Name"
        else
            bufname = vim.fn.fnamemodify(bufname, ":t")
        end

        local tabname = string.format(" %d:[%s] ", idx, bufname)
        table.insert(tabs, {
            name = tabname,
            pos = pos,
        })
        pos = pos + #tabname
    end
    return tabs
end

local linepos = 1

function Tabline.build_tabline()
    local line = ""
    local hlsel = "%#TabLineSel#"
    local hlline = "%#TabLine#"

    local tabs = get_tabs()
    local curr = vim.fn.tabpagenr()

    for idx, tab in pairs(tabs) do
        local tabname = tab.name
        if idx == curr then
            tabname = hlsel .. tab.name .. hlline
        end
        line = line .. tabname
    end

    local cols = vim.o.columns
    local currtab = tabs[curr]
    if currtab.pos < linepos then
        linepos = currtab.pos
    elseif currtab.pos + #currtab.name > linepos + cols then
        linepos = currtab.pos + #currtab.name - cols
    end

    return hlline .. line:sub(linepos, linepos + cols + #hlsel + #hlline - 1) .. "%#TabLineFill#"
end

vim.opt.tabline = "%!v:lua.Tabline.build_tabline()"
