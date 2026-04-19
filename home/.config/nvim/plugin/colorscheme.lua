vim.cmd.colorscheme "default"

local ns = 0
local none = "NONE"

---@param name string
local function get(name)
    return vim.api.nvim_get_hl(ns, { name = name })
end

---@param name string
---@param color vim.api.keyset.highlight
local function set(name, color)
    vim.api.nvim_set_hl(ns, name, color)
end

---@param name string
---@param def vim.api.keyset.highlight
local function ext(name, def)
    set(name, vim.tbl_extend("force", {}, get(name), def))
end

ext("Normal", { bg = "#000000" })

local Comment = get "Comment"
ext("Comment", { italic = true, bold = false })
ext("LineNr", { fg = Comment.fg })
ext("SignColumn", { bg = none })
ext("EndOfBuffer", { fg = Comment.fg })

local Pmenu = get "Pmenu"
set("NormalFloat", { bg = Pmenu.bg, blend = 5 })
set("FloatBorder", { link = "NormalFloat" })
set("FloatTitle", { link = "NormalFloat" })

local DiagnosticHint = get "DiagnosticHint"
local DiagnosticWarn = get "DiagnosticWarn"
set("DiagnosticUnnecessary", { sp = DiagnosticHint.fg, underline = true })
set("SpellCap", { sp = DiagnosticHint.sp, undercurl = true })
set("SpellBad", { sp = DiagnosticWarn.sp, undercurl = true })

set("WinSeparator", { link = "LineNr" })
set("NonText", { link = "LineNr" })

set("StatusLine", { fg = Comment.fg, bg = none })
set("StatusLineTerm", { link = "StatusLine" })
set("StatusLineTermNC", { link = "StatusLine" })
set("ModeMsg", { link = "StatusLine" })

local Normal = get "Normal"
set("TabLine", { link = "StatusLine" })
set("TabLineFill", { link = "StatusLine" })
ext("TabLineSel", { bg = Normal.bg, fg = Normal.fg })

ext("DiffAdd", { fg = none })
ext("DiffChange", { fg = none })
ext("DiffDelete", { fg = none })
ext("DiffText", { fg = none })
