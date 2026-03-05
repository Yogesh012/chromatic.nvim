--- chromatic/compat.lua
--- Legacy Vim colorscheme compatibility shim.
--- ONLY invoked when a registry entry has `legacy = true`.
--- Modern Lua themes (tokyonight, catppuccin, etc.) skip this entirely.

local M = {}

--- Map a cterm 256-color index to its approximate hex RGB string.
---@param idx number
---@return string  e.g. "#5f87af"
local function cterm_to_hex(idx)
  local base16 = {
    [0]="#1c1c1c",[1]="#af0000",[2]="#00af00",[3]="#afaf00",
    [4]="#0087af",[5]="#af00af",[6]="#00afaf",[7]="#c0c0c0",
    [8]="#767676",[9]="#ff5f5f",[10]="#5fff5f",[11]="#ffff5f",
    [12]="#5f87ff",[13]="#ff5fff",[14]="#5fffff",[15]="#ffffff",
  }
  if idx < 16 then return base16[idx] or "#ffffff" end
  if idx >= 232 then
    local v = 8 + (idx - 232) * 10
    return string.format("#%02x%02x%02x", v, v, v)
  end
  idx = idx - 16
  local b = idx % 6
  local g = math.floor(idx / 6) % 6
  local r = math.floor(idx / 36)
  local function cube(n) return n == 0 and 0 or (55 + n * 40) end
  return string.format("#%02x%02x%02x", cube(r), cube(g), cube(b))
end

local function hl_attr(name, attr)
  local id = vim.fn.synIDtrans(vim.fn.hlID(name))
  return vim.fn.synIDattr(id, attr) or ""
end

--- Convert every cterm-only highlight group to its GUI equivalent.
--- Safe to call on any colorscheme; no-op for groups that already have gui attrs.
function M.patch_cterm_to_gui()
  local groups = vim.fn.getcompletion("", "highlight")
  for _, name in ipairs(groups) do
    local ok, info = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    if not ok or not info then goto continue end
    if not info.fg and not info.bg then
      local ctermfg = tonumber(hl_attr(name, "ctermfg"))
      local ctermbg = tonumber(hl_attr(name, "ctermbg"))
      local new_hl = {}
      if ctermfg then new_hl.fg = cterm_to_hex(ctermfg) end
      if ctermbg then new_hl.bg = cterm_to_hex(ctermbg) end
      if next(new_hl) then
        if info.bold      then new_hl.bold      = true end
        if info.italic    then new_hl.italic     = true end
        if info.underline then new_hl.underline  = true end
        if info.reverse   then new_hl.reverse    = true end
        pcall(vim.api.nvim_set_hl, 0, name, new_hl)
      end
    end
    ::continue::
  end
end

--- Inject sensible defaults for Neovim-specific UI groups that legacy themes
--- didn't define (NormalFloat, FloatBorder, diagnostic groups, etc.).
function M.fill_missing_groups()
  local normal_ok, normal = pcall(vim.api.nvim_get_hl, 0, { name = "Normal", link = false })
  local fg = (normal_ok and normal.fg) and string.format("#%06x", normal.fg) or "#c0c0c0"
  local bg = (normal_ok and normal.bg) and string.format("#%06x", normal.bg) or "#1c1c1c"

  local function fill(name, attrs)
    local ok, ex = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    if not ok or (not ex.fg and not ex.bg and not ex.link) then
      pcall(vim.api.nvim_set_hl, 0, name, attrs)
    end
  end

  fill("NormalFloat",           { fg=fg,        bg=bg })
  fill("FloatBorder",           { fg="#5c6370", bg=bg })
  fill("WinSeparator",          { fg="#3b3b3b", bg=bg })
  fill("DiagnosticVirtualText", { fg="#767676" })
  fill("DiagnosticError",       { fg="#f44747" })
  fill("DiagnosticWarn",        { fg="#ff8800" })
  fill("DiagnosticInfo",        { fg="#75beff" })
  fill("DiagnosticHint",        { fg="#4ec9b0" })
  fill("StatusLine",            { fg=fg,        bg="#3a3a3a" })
  fill("StatusLineNC",          { fg="#767676", bg="#2a2a2a" })
  fill("CursorLine",            { bg="#2a2a2a" })
  fill("LineNr",                { fg="#5a5a5a" })
  fill("CursorLineNr",          { fg="#d4d4d4", bold=true })
  fill("Pmenu",                 { fg=fg,        bg="#252526" })
  fill("PmenuSel",              { fg="#ffffff", bg="#094771" })
end

--- Full compat pipeline for a legacy Vim colorscheme.
---@param name  string  colorscheme name
---@param entry table   registry entry
---@return boolean      true on success
function M.apply_legacy(name, entry)
  vim.opt.background = entry.background
  vim.opt.termguicolors = true
  local ok, err = pcall(vim.cmd, "colorscheme " .. name)
  if not ok then
    vim.notify(
      "[chromatic] Failed to load legacy colorscheme '" .. name .. "': " .. tostring(err),
      vim.log.levels.WARN
    )
    return false
  end
  M.patch_cterm_to_gui()
  M.fill_missing_groups()
  return true
end

return M
