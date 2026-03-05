# Changelog

All notable changes to chromatic.nvim will be documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).  
This project uses [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

_Changes in progress on main that have not been released yet._

---

## [0.1.0] — 2026-03-06

### Added
- Random colorscheme selection on startup from installed theme plugins
- Dark / light mode filtering via `mode` config option
- User-defined `allowlist` to restrict the candidate pool
- Session persistence (`persist` option) — replay last applied theme on next open
- Runtime settings stored in `chromatic_state.json` — survive restarts without editing config files
- `:ChromaticNext` — pick a new random theme immediately
- `:ChromaticMode [dark|light|any]` — set mode filter (persisted, tab-completable)
- `:ChromaticConfig` — interactive `vim.ui.select` settings picker
- `:ChromaticInfo` — print current theme and active settings
- Built-in catalog of 30+ popular themes with background metadata
- `extra_themes` config option for user-defined catalog extensions
- Legacy Vim theme compatibility shim (cterm→GUI color conversion, missing UI group fill)
- Automatic runtimepath priming — lazy-installed themes visible to `:colorscheme` completion
- `ColorScheme` autocmd sync — manual `:colorscheme X` calls tracked automatically
- lualine.nvim sync after every theme change (`sync_lualine` option)
- `notify` option: `"notify"` / `"echo"` / `"silent"`
- Compatible with lazy.nvim, vim-plug, packer, and any rtp-based plugin manager
- Full vimdoc help (`:h chromatic`)
