--- chromatic/state.lua
--- Runtime user-preference persistence.
--- Reads/writes ~/.local/share/nvim/chromatic_state.json
---
--- Priority (highest wins):  state.json  >  setup() opts
---
--- Schema:
---   { "mode": "dark"|"light"|null, "persist": bool, "last_theme": string }

local M = {}

local _path  = vim.fn.stdpath("data") .. "/chromatic_state.json"
local _cache = nil

local function read_file(p)
  local f = io.open(p, "r"); if not f then return nil end
  local s = f:read("*a"); f:close(); return s
end

local function write_file(p, s)
  local f = io.open(p, "w")
  if not f then
    vim.notify("[chromatic] Cannot write state file: " .. p, vim.log.levels.ERROR)
    return false
  end
  f:write(s); f:close(); return true
end

--- Load and cache the state file. Returns {} on any error.
---@return table
function M.load()
  if _cache then return _cache end
  local raw = read_file(_path)
  if not raw or raw == "" then _cache = {}; return _cache end
  local ok, parsed = pcall(vim.json.decode, raw)
  _cache = (ok and type(parsed) == "table") and parsed or {}
  return _cache
end

--- Persist the full state table to disk.
---@param tbl table
function M.save(tbl)
  _cache = tbl
  local ok, json = pcall(vim.json.encode, tbl)
  if ok then write_file(_path, json) end
end

--- Get one key from runtime state.
---@param key string
---@return any
function M.get(key) return M.load()[key] end

--- Set one key and immediately persist.
---@param key   string
---@param value any
function M.set(key, value)
  local s = M.load(); s[key] = value; M.save(s)
end

--- Clear all runtime state (reset to setup() defaults).
function M.reset()
  _cache = {}; write_file(_path, "{}")
end

--- Return the effective configuration: setup() opts merged with runtime state.
--- State values take priority over setup() opts.
---@return table
function M.effective_config()
  local base = vim.deepcopy(require("chromatic.config").get())
  local s = M.load()

  -- Runtime overrides: only apply if the key is explicitly present in state
  if s.mode ~= nil    then base.mode    = s.mode    end
  if s.persist ~= nil then base.persist = s.persist end

  -- "nil" is stored as the string "nil" in JSON to mean "user explicitly cleared mode"
  if base.mode == "nil" then base.mode = nil end

  return base
end

return M
