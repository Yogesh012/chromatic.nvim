# chromatic.nvim

> A smart, random colorscheme selector for Neovim

chromatic.nvim picks a random theme from your installed colorscheme plugins every time Neovim opens — with dark/light filtering, allowlists, session persistence, and full legacy Vim theme compatibility.

## Features

- 🎲 **Random theme on startup** — never look at the same colors twice
- 🌑 **Dark / light mode filtering** — restrict the pool to your preferred background
- 📋 **Allowlist support** — curate exactly which themes are candidates
- 💾 **Session persistence** — optionally keep the same theme across restarts
- ⚡ **Zero startup cost** — only the chosen theme is loaded; all others stay lazy
- 🔄 **`:colorscheme` sync** — manual `:colorscheme X` calls are tracked automatically
- 🗂️ **Extensible registry** — 30+ built-in themes, easily add your own
- 🏛️ **Legacy Vim compat** — automatically patches cterm→GUI colors for old themes
- 🎛️ **Runtime settings** — change mode/persist without editing any Lua file

## Requirements

- Neovim >= 0.9
- [lazy.nvim](https://github.com/folke/lazy.nvim) *(recommended)*

## Installation

### lazy.nvim

```lua
{
  "yourusername/chromatic.nvim",
  lazy     = false,
  priority = 999,
  opts = {
    mode    = "dark",   -- "dark" | "light" | nil (any)
    persist = false,    -- true = replay last theme on next open
  },
}
```

### Local development path

```lua
{
  dir      = "~/chromatic.nvim",
  name     = "chromatic.nvim",
  lazy     = false,
  priority = 999,
  opts     = { mode = "dark" },
}
```

## Configuration

All options with their defaults:

```lua
require("chromatic").setup({
  -- Master switch. false = apply `fallback` with no randomisation
  enabled = true,

  -- Colorscheme used when enabled=false or no candidates are found
  fallback = "default",

  -- Mode filter: "dark" | "light" | nil (any)
  mode = nil,

  -- If non-empty, only themes in this list are candidates
  allowlist = {},

  -- Add themes beyond the built-in catalog
  extra_themes = {},

  -- false = fresh random each open  |  true = replay last applied theme
  persist = false,

  -- Re-sync lualine.nvim theme after every colorscheme change
  sync_lualine = true,

  -- Notification style: "notify" | "echo" | "silent"
  notify = "notify",
})
```

## Adding themes to the pool

1. Install the theme plugin (`lazy = true` is fine — chromatic loads it on demand):

```lua
-- In your lazy.nvim plugin list:
{ "ellisonleao/gruvbox.nvim", lazy = true },
{ "catppuccin/nvim",          lazy = true, name = "catppuccin" },
```

2. The theme is automatically detected if it's in chromatic's built-in catalog  
   (see the full list in [`lua/chromatic/registry.lua`](lua/chromatic/registry.lua)).  
   To add an unlisted theme:

```lua
opts = {
  extra_themes = {
    { name = "my-theme", background = "dark", plugin = "my-theme.nvim" },
  },
}
```

## Commands

| Command | Description |
|---------|-------------|
| `:ChromaticNext` | Pick a new random theme immediately |
| `:ChromaticMode dark\|light\|any` | Set mode filter (persisted, tab-completable) |
| `:ChromaticConfig` | Interactive `vim.ui.select` settings picker |
| `:ChromaticInfo` | Show current theme + active settings |

## Suggested keymaps

chromatic.nvim doesn't claim any keys — add your own:

```lua
local map = vim.keymap.set
map("n", "<leader>Tn", "<cmd>ChromaticNext<cr>",       { desc = "Theme: new random" })
map("n", "<leader>Tc", "<cmd>ChromaticConfig<cr>",     { desc = "Theme: settings" })
map("n", "<leader>Td", "<cmd>ChromaticMode dark<cr>",  { desc = "Theme: dark mode" })
map("n", "<leader>Tl", "<cmd>ChromaticMode light<cr>", { desc = "Theme: light mode" })
map("n", "<leader>Ta", "<cmd>ChromaticMode any<cr>",   { desc = "Theme: any mode" })
map("n", "<leader>Ti", "<cmd>ChromaticInfo<cr>",       { desc = "Theme: info" })
```

## Runtime settings

Settings changed via `:ChromaticMode` or `:ChromaticConfig` are persisted to  
`~/.local/share/nvim/chromatic_state.json` and survive restarts — no config file editing needed.

Delete the file to reset to your `setup()` defaults.

## Lua API

```lua
local chromatic = require("chromatic")

chromatic.setup(opts)        -- configure (usually done via lazy opts)
chromatic.next()             -- pick new random theme now
chromatic.current()          -- return active colorscheme name
chromatic.list_available()   -- return filtered candidate table
chromatic.set_mode("dark")   -- set + persist mode
chromatic.set_persist(true)  -- toggle + persist
```

## License

MIT — see [LICENSE](LICENSE)
