# Luacheck configuration for Neovim Lua projects


globals = {
  "vim",
  "use",
  "describe",
  "it",
  "before_each", "after_each",
  "require"
}

unused_args = false

unused = false

shadowing = false

ignore_inline_comments = true

allow_defined_top = true

files["**.lua"] = true

cache = true
