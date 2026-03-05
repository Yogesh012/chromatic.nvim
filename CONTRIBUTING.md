# Contributing to chromatic.nvim

Thanks for your interest in contributing! Here's everything you need to know.

---

## Getting started

```bash
git clone https://github.com/Yogesh012/chromatic.nvim
cd chromatic.nvim
```

The plugin is pure Lua — no build step required.

---

## Repository layout

```
lua/chromatic/
  config.lua    — setup() defaults and merge logic
  registry.lua  — built-in theme catalog
  compat.lua    — legacy Vim theme compat shims
  state.lua     — runtime settings persistence
  init.lua      — core engine + public API
  ui.lua        — :Chromatic* user commands

plugin/
  chromatic.lua — auto-sourced entry point (VimEnter hook)

doc/
  chromatic.txt — vimdoc help (:h chromatic)

tests/          — busted test suite (see Testing below)
```

---

## Linting

We use **luacheck**. Install and run:

```bash
luarocks install luacheck
luacheck lua/ plugin/ --codes
```

The `.luacheckrc` at the root configures the allowed globals. CI runs this on every PR.

---

## Testing

We use **busted**:

```bash
luarocks install busted
busted tests/
```

Or headless via Neovim:

```bash
nvim --headless -c "PlenaryBustedDirectory tests/" -c "qa"
```

---

## Adding themes to the registry

If you want to add a theme to the built-in catalog, edit `lua/chromatic/registry.lua`:

```lua
-- Add to M.catalog:
{ name="your-theme", background="dark", plugin="your-theme.nvim", parent="author/your-theme.nvim" },
```

Fields:
- `name` — the string passed to `:colorscheme`
- `background` — `"dark"` or `"light"`
- `plugin` — the directory slug lazy.nvim uses (usually the repo name without the author)
- `parent` — full `"author/repo"` (informational only)
- `legacy = true` — set this for old Vim themes that need cterm→GUI patching

---

## Pull request guidelines

1. Keep PRs focused — one feature/fix per PR
2. Run luacheck before pushing
3. Update `doc/chromatic.txt` if you change any user-facing behaviour
4. Add an entry to `CHANGELOG.md` under `[Unreleased]`
5. Use the PR template checklist

---

## Branch protection

The `main` branch is protected:
- All PRs require at least one approval
- CI (luacheck + tests) must pass before merging
- Force-pushing to main is disabled

Please make feature branches off `main`:

```bash
git checkout -b feat/my-feature
# work, commit...
git push origin feat/my-feature
# open PR to main
```
