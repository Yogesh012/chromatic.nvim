-- .luacheckrc — chromatic.nvim
-- Luacheck configuration following common Neovim plugin standards.
-- Ref: https://luacheck.readthedocs.io/en/stable/config.html

-- ── Line length ───────────────────────────────────────────────────────────────
-- Slightly relaxed from the 120 default to accommodate aligned table literals
-- in registry.lua without silencing the warning category entirely.
max_line_length = 130

-- ── Neovim globals ────────────────────────────────────────────────────────────
-- Declare the top-level `vim` table so luacheck doesn't flag every vim.* call.
globals = {
  "vim",
}
unused_args = false

-- Allow variables that are defined but only used later (top-level module vars).
allow_defined_top = true

-- Shadowing is a valid Lua pattern (e.g. upvalue narrowing inside closures).
allow_defined = true

-- ── Warnings to ignore globally ──────────────────────────────────────────────
-- 212: unused argument     — already handled by unused_args = false above,
--                            but listed here for explicitness.
-- 122: setting read-only global — fired by some vim.* meta-method patterns;
--                                 not a real issue in Neovim plugins.
ignore = {
  "212", -- unused argument
  "122", -- setting a read-only global field
  "631", -- too many lines in a block
}

-- ── Per-path overrides ────────────────────────────────────────────────────────
-- plugin/ entry-point: the file runs at load time and may set package-level
-- state; suppress the "defined but not used" noise for module-level vars.
files["plugin/chromatic.lua"] = {
  ignore = { "211", "212" },
}

-- tests/: busted DSL globals are only valid inside spec files.
files["tests/spec/*.lua"] = {
  globals = { "describe", "it", "before_each", "after_each",
              "assert", "pending", "spy", "stub", "mock" },
}
