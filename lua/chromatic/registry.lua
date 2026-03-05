--- chromatic/registry.lua
--- Built-in catalog of known colorscheme themes.
--- Users can extend this via the `extra_themes` config option.
---
--- Entry schema:
---   name       (string)           — colorscheme name passed to :colorscheme
---   background ("dark"|"light")   — used for mode filtering
---   plugin     (string|nil)       — lazy.nvim plugin directory slug; nil = built-in
---   parent     (string|nil)       — full "author/repo" slug (informational)
---   legacy     (boolean|nil)      — true = apply compat shims (cterm→GUI, missing groups)
---   _key       (string|nil)       — dedup override for same-name dark/light pairs

local M = {}

M.catalog = {
  -- ── Dark themes ─────────────────────────────────────────────────────────────
  { name="tokyonight-storm",      background="dark",  plugin="tokyonight.nvim",    parent="folke/tokyonight.nvim" },
  { name="tokyonight-night",      background="dark",  plugin="tokyonight.nvim",    parent="folke/tokyonight.nvim" },
  { name="tokyonight-moon",       background="dark",  plugin="tokyonight.nvim",    parent="folke/tokyonight.nvim" },
  { name="catppuccin-mocha",      background="dark",  plugin="nvim",               parent="catppuccin/nvim" },
  { name="catppuccin-macchiato",  background="dark",  plugin="nvim",               parent="catppuccin/nvim" },
  { name="catppuccin-frappe",     background="dark",  plugin="nvim",               parent="catppuccin/nvim" },
  { name="gruvbox",               background="dark",  plugin="gruvbox.nvim",        parent="ellisonleao/gruvbox.nvim" },
  { name="kanagawa-wave",         background="dark",  plugin="kanagawa.nvim",       parent="rebelot/kanagawa.nvim" },
  { name="kanagawa-dragon",       background="dark",  plugin="kanagawa.nvim",       parent="rebelot/kanagawa.nvim" },
  { name="rose-pine",             background="dark",  plugin="neovim",              parent="rose-pine/neovim" },
  { name="rose-pine-moon",        background="dark",  plugin="neovim",              parent="rose-pine/neovim" },
  { name="nightfox",              background="dark",  plugin="nightfox.nvim",       parent="EdenEast/nightfox.nvim" },
  { name="carbonfox",             background="dark",  plugin="nightfox.nvim",       parent="EdenEast/nightfox.nvim" },
  { name="duskfox",               background="dark",  plugin="nightfox.nvim",       parent="EdenEast/nightfox.nvim" },
  { name="nordfox",               background="dark",  plugin="nightfox.nvim",       parent="EdenEast/nightfox.nvim" },
  { name="onedark",               background="dark",  plugin="onedark.nvim",        parent="navarasu/onedark.nvim" },
  { name="everforest",            background="dark",  plugin="everforest",          parent="sainnhe/everforest" },
  { name="dracula",               background="dark",  plugin="dracula.nvim",        parent="Mofiqul/dracula.nvim" },
  { name="nord",                  background="dark",  plugin="nord.nvim",           parent="shaunsingh/nord.nvim" },
  { name="github_dark",           background="dark",  plugin="github-nvim-theme",   parent="projekt0n/github-nvim-theme" },
  { name="ayu-mirage",            background="dark",  plugin="neovim-ayu",          parent="Shatur/neovim-ayu" },
  { name="ayu-dark",              background="dark",  plugin="neovim-ayu",          parent="Shatur/neovim-ayu" },
  { name="material",              background="dark",  plugin="material.nvim",       parent="marko-cerovac/material.nvim" },
  { name="melange",               background="dark",  plugin="melange-nvim",        parent="savq/melange-nvim" },
  { name="monokai-pro",           background="dark",  plugin="monokai-pro.nvim",    parent="loctvl842/monokai-pro.nvim" },
  { name="cyberdream",            background="dark",  plugin="cyberdream.nvim",     parent="scottmckendry/cyberdream.nvim" },

  -- ── Light themes ────────────────────────────────────────────────────────────
  { name="tokyonight-day",        background="light", plugin="tokyonight.nvim",    parent="folke/tokyonight.nvim" },
  { name="catppuccin-latte",      background="light", plugin="nvim",               parent="catppuccin/nvim" },
  { name="rose-pine-dawn",        background="light", plugin="neovim",             parent="rose-pine/neovim" },
  { name="dayfox",                background="light", plugin="nightfox.nvim",      parent="EdenEast/nightfox.nvim" },
  { name="github_light",          background="light", plugin="github-nvim-theme",  parent="projekt0n/github-nvim-theme" },
  { name="ayu-light",             background="light", plugin="neovim-ayu",         parent="Shatur/neovim-ayu" },
  {
    -- everforest light: same :colorscheme name as dark, differentiated via background.
    -- _key prevents the dedup pass from dropping one of the two.
    name="everforest", background="light", plugin="everforest", parent="sainnhe/everforest",
    _key="everforest-light",
  },
  { name="melange",               background="light", plugin="melange-nvim",       parent="savq/melange-nvim",
    _key="melange-light" },

  -- ── Legacy / built-in Vim themes (compat shims applied automatically) ───────
  { name="desert",     background="dark",  plugin=nil, legacy=true },
  { name="slate",      background="dark",  plugin=nil, legacy=true },
  { name="habamax",    background="dark",  plugin=nil, legacy=true },
  { name="zaibatsu",   background="dark",  plugin=nil, legacy=true },
  { name="lunaperche", background="dark",  plugin=nil, legacy=true },
  { name="morning",    background="light", plugin=nil, legacy=true },
  { name="peachpuff",  background="light", plugin=nil, legacy=true },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

--- Build the full working catalog = built-in entries + user's extra_themes.
---@return table[]
function M.all()
  local cfg = require("chromatic.config").get()
  if cfg.extra_themes and #cfg.extra_themes > 0 then
    local merged = vim.list_extend(vim.deepcopy(M.catalog), cfg.extra_themes)
    return merged
  end
  return M.catalog
end

--- Returns catalog entries whose theme is detectable as installed.
--- Detection strategy (in order):
---   1. lazy.nvim: check require("lazy.core.config").plugins   (lazy=true safe)
---   2. Universal fallback: check vim.fn.getcompletion("","color") — returns all
---      colorscheme names currently findable in the rtp. Works with vim-plug,
---      packer, rocks.nvim, or any manager that eagerly adds plugins to rtp.
--- Built-in themes (plugin = nil) are always included regardless.
---@return table[]
function M.installed()
  local result = {}

  -- ── Strategy 1: lazy.nvim plugin map ──────────────────────────────────────
  local use_lazy = false
  local lazy_plugins = {}
  local lazy_ok, lazy_cfg = pcall(require, "lazy.core.config")
  if lazy_ok and lazy_cfg.plugins then
    lazy_plugins = lazy_cfg.plugins
    use_lazy = true
  end

  -- ── Strategy 2: universal colorscheme name lookup ─────────────────────────
  -- Build a set of all colorscheme names visible in the current rtp.
  -- This works for any plugin manager that loads plugins eagerly.
  local rtp_colors = {}
  if not use_lazy then
    for _, name in ipairs(vim.fn.getcompletion("", "color")) do
      rtp_colors[name] = true
    end
  end

  local seen = {}
  for _, entry in ipairs(M.all()) do
    local key = entry._key or entry.name
    if seen[key] then goto continue end
    seen[key] = true

    if entry.plugin == nil then
      -- Built-in / legacy Vim theme — always available
      table.insert(result, entry)
    elseif use_lazy then
      -- lazy.nvim path: plugin registered in lazy's plugin map
      if lazy_plugins[entry.plugin] then
        table.insert(result, entry)
      end
    else
      -- Universal fallback: colorscheme file exists in rtp
      if rtp_colors[entry.name] then
        table.insert(result, entry)
      end
    end

    ::continue::
  end

  return result
end

--- Find a single entry by name (searches the full merged catalog).
---@param name string
---@return table|nil
function M.find(name)
  for _, entry in ipairs(M.all()) do
    if entry.name == name then return entry end
  end
  return nil
end

return M
