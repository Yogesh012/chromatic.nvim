--- chromatic/config.lua
--- Default configuration and setup() merge logic.
--- This is the single source of truth for all plugin defaults.
--- Users never require this directly — they call require("chromatic").setup({}).

local M = {}

--- Default configuration values.
--- Documented fully in doc/chromatic.txt and README.md.
M.defaults = {
  -- Master switch. false = apply `fallback` colorscheme with no randomisation.
  enabled = true,

  -- Colorscheme applied when enabled = false, or when no candidates are found.
  fallback = "default",

  -- Background mode filter: "dark" | "light" | nil (nil = any)
  mode = nil,

  -- Allowlist: if non-empty, only these theme names are candidates.
  -- Example: { "tokyonight-storm", "gruvbox", "rose-pine" }
  allowlist = {},

  -- Extra themes added to the built-in catalog.
  -- Each entry must have: name (string), background ("dark"|"light"), plugin (string|nil)
  -- Optional: legacy (bool), _key (string, only for same-name dark/light pairs)
  extra_themes = {},

  -- persist = false → fresh random theme every nvim open
  -- persist = true  → replay the last applied theme on every open
  persist = false,

  -- Automatically re-apply lualine theme after every colorscheme switch.
  -- Only takes effect if lualine.nvim is installed.
  sync_lualine = true,

  -- Notification style for theme announcements.
  -- "notify" = use vim.notify  |  "echo" = simple :echo  |  "silent" = no notification
  notify = "notify",
}

-- Internal: the live merged config for this session.
-- Populated by setup(), read by the engine via M.get().
local _config = nil

--- Merge user opts with defaults and store the result.
--- Called once by require("chromatic").setup(opts).
---@param opts table|nil
function M.apply(opts)
  _config = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

--- Return the active merged config.
--- Initialises from defaults if setup() was never called.
---@return table
function M.get()
  if not _config then
    _config = vim.deepcopy(M.defaults)
  end
  return _config
end

return M
