--- plugin/chromatic.lua
--- Auto-sourced by Neovim when chromatic.nvim is loaded via any plugin manager.
--- Registers the VimEnter startup hook and all user commands.
--- Users never need to call anything in this file directly.

-- Guard: only run once per session
if vim.g.chromatic_loaded then return end
vim.g.chromatic_loaded = true

-- Register commands immediately (they are lightweight wrappers)
require("chromatic.ui").setup()

-- Apply the theme after all plugins have finished loading.
-- Using VimEnter ensures lazy.nvim has registered all plugins before we
-- query lazy.core.config.plugins in registry.installed().
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("ChromaticStartup", { clear = true }),
  once  = true,
  callback = function()
    -- ensure_applied() is idempotent: if tokyonight (or another non-lazy fallback)
    -- has already applied a colorscheme, this still re-runs to pick a random one
    -- (the ColorScheme autocmd inside init.lua sets _applied = true, but
    -- ensure_applied checks _applied only to prevent double-firing on the same
    -- VimEnter in edge cases like nested nvim sessions).
    require("chromatic").apply()
  end,
})
