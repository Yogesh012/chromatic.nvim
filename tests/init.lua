-- tests/init.lua
-- Bootstrap for running busted specs inside Neovim's embedded LuaJIT.
--
-- Run all specs:
--   nvim --headless -u tests/init.lua -c "lua _G.arg={[0]='busted'} require('busted.runner')()"
--
-- Note: busted calls os.exit() on completion — no need for -c "qa!".
-- Test discovery is configured in .busted (root = tests/spec/, pattern = _spec.lua).

-- ── 1. Add plugin source to runtimepath ──────────────────────────────────────
local plugin_root = vim.fn.fnamemodify(
  debug.getinfo(1, "S").source:sub(2), ":h:h"
)
vim.opt.rtp:prepend(plugin_root)

-- ── 2. Inject luarocks paths so busted can be required inside nvim's LuaJIT ──
-- busted was installed with: luarocks --lua-version=5.1 --lua-dir=$(brew --prefix luajit) install busted
-- which places Lua files in ~/.luarocks/share/lua/5.1/ and C libs in ~/.luarocks/lib/lua/5.1/
local function addpath(p)
  if p:find("%.so$") or p:find("%.dylib$") then
    package.cpath = p .. ";" .. package.cpath
  else
    package.path  = p .. ";" .. package.path
  end
end

for _, p in ipairs({
  vim.fn.expand("~/.luarocks/share/lua/5.1/?.lua"),
  vim.fn.expand("~/.luarocks/share/lua/5.1/?/init.lua"),
  vim.fn.expand("~/.luarocks/lib/lua/5.1/?.so"),
  "/opt/homebrew/share/lua/5.1/?.lua",
  "/opt/homebrew/share/lua/5.1/?/init.lua",
  "/opt/homebrew/lib/lua/5.1/?.so",
}) do addpath(p) end
