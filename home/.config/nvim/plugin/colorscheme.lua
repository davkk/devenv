local bit = require "bit"

vim.cmd.colorscheme "default"

local ns = 0
local none = "NONE"

---@param color1 number
---@param color2 number
---@param amount number
local function blend(color1, color2, amount)
    if color1 == nil or color2 == nil then
        return nil
    end
    amount = math.max(0, math.min(1, amount))

    local r1 = bit.rshift(bit.band(color1, 0xff0000), 16)
    local g1 = bit.rshift(bit.band(color1, 0x00ff00), 8)
    local b1 = bit.band(color1, 0x0000ff)

    local r2 = bit.rshift(bit.band(color2, 0xff0000), 16)
    local g2 = bit.rshift(bit.band(color2, 0x00ff00), 8)
    local b2 = bit.band(color2, 0x0000ff)

    local r = math.floor(r1 * (1 - amount) + r2 * amount)
    local g = math.floor(g1 * (1 - amount) + g2 * amount)
    local b = math.floor(b1 * (1 - amount) + b2 * amount)

    return bit.bor(bit.lshift(r, 16), bit.lshift(g, 8), b)
end

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

local Normal = get "Normal"
ext("LineNr", { fg = blend(Normal.bg, Normal.fg, 0.5) })

local LineNr = get "LineNr"
set("TreesitterContextLineNr", { fg = LineNr.fg, bold = true })
ext("Comment", { fg = LineNr.fg, italic = true, bold = false })
ext("Constant", { fg = blend(Normal.bg, Normal.fg, 0.9) })

local Pmenu = get "Pmenu"
set("NormalFloat", { bg = Pmenu.bg, blend = 5 })
set("FloatBorder", { link = "NormalFloat" })
set("FloatTitle", { link = "NormalFloat" })

local DiagnosticHint = get "DiagnosticHint"
local DiagnosticWarn = get "DiagnosticWarn"
set("DiagnosticUnnecessary", { sp = DiagnosticHint.fg, underline = true })
set("SpellCap", { sp = DiagnosticHint.sp, undercurl = true })
set("SpellBad", { sp = DiagnosticWarn.sp, undercurl = true })

set("EndOfBuffer", { link = "LineNr" })
set("WinSeparator", { link = "LineNr" })
set("NonText", { link = "LineNr" })

set("StatusLine", { fg = LineNr.fg, bg = none })
set("StatusLineTerm", { link = "StatusLine" })
set("StatusLineTermNC", { link = "StatusLine" })
set("ModeMsg", { link = "StatusLine" })

Normal = get "Normal"
set("TabLine", { link = "StatusLine" })
set("TabLineFill", { link = "StatusLine" })
ext("TabLineSel", { bg = Normal.bg, fg = Normal.fg })

local DiffAdd = get "DiffAdd"
local DiffChange = get "DiffChange"
local DiffDelete = get "DiffDelete"
local DiffText = get "DiffText"

set("DiffAdd", { fg = none, bg = blend(Normal.bg, DiffAdd.bg, 0.6) })
set("DiffChange", { fg = none, bg = blend(Normal.bg, DiffChange.bg, 0.5) })
set("DiffDelete", { fg = none, bg = blend(Normal.bg, DiffDelete.fg, 0.3) })
set("DiffText", { fg = none, bg = blend(Normal.bg, DiffText.bg, 0.7) })

set("diffAdded", { link = "DiffAdd" })
set("diffChanged", { link = "DiffChange" })
set("diffRemoved", { link = "DiffDelete" })

local NormalFloat = get "NormalFloat"
set("FzfLuaNormal", { bg = NormalFloat.bg, fg = NormalFloat.fg, blend = 5 })
set("FzfLuaBorder", { bg = NormalFloat.bg, fg = NormalFloat.fg, blend = 5 })
set("FzfLuaTitle", { bg = NormalFloat.bg, fg = NormalFloat.fg, blend = 5 })

local Function = get "Function"
set("QuickFixLine", { bg = blend(Normal.bg, Function.fg, 0.2), fg = none })
