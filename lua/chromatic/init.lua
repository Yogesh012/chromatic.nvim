--- chromatic/init.lua
--- Core engine + public API for chromatic.nvim
---
--- setup() is the only function users call directly from their config.
--- All other functions are available for advanced use or keymap targets.
---
--- Public API:
---   chromatic.setup(opts)        configure the plugin (call once from config)
---   chromatic.apply()            startup entry point — called by plugin/chromatic.lua
---   chromatic.next()             pick & apply a new random theme right now
---   chromatic.current()          return name of the active colorscheme
---   chromatic.list_available()   return filtered candidate list
---   chromatic.set_mode(m)        "dark"|"light"|nil, persisted
---   chromatic.set_persist(bool)  toggle persist, persisted

local M = {}

local _applied = false -- has a theme been applied this session?
local _current = nil -- name of the currently active colorscheme

-- ─────────────────────────────────────────────────────────────────────────────
-- Lazy-loaded sub-modules (avoid loading everything at require time)
-- ─────────────────────────────────────────────────────────────────────────────
local function registry()
	return require("chromatic.registry")
end
local function compat()
	return require("chromatic.compat")
end
local function state()
	return require("chromatic.state")
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Internal helpers
-- ─────────────────────────────────────────────────────────────────────────────

--- Add all installed theme plugin directories to Neovim's runtimepath.
--- This makes :colorscheme tab-completion and manual :colorscheme calls work
--- for lazy=true plugin themes without actually loading their configs.
local function prime_colorscheme_paths()
	local lazy_root = vim.fn.stdpath("data") .. "/lazy"
	local rtp = vim.opt.rtp:get()
	local in_rtp = {}
	for _, p in ipairs(rtp) do
		in_rtp[p] = true
	end

	for _, entry in ipairs(registry().all()) do
		if entry.plugin then
			local dir = lazy_root .. "/" .. entry.plugin
			if not in_rtp[dir] and vim.fn.isdirectory(dir) == 1 then
				vim.opt.rtp:append(dir)
				in_rtp[dir] = true
			end
		end
	end
end

--- Lazy-load one plugin through lazy.nvim if it hasn't been loaded yet.
--- No-op for built-in themes (plugin = nil) and if lazy is unavailable.
---@param plugin_name string|nil
local function lazy_load(plugin_name)
	if not plugin_name then
		return
	end
	local ok, lazy = pcall(require, "lazy")
	if ok then
		pcall(lazy.load, { plugins = { plugin_name } })
	end
end

--- Apply a modern Lua colorscheme (no compat shims).
---@param entry table
---@return boolean
local function apply_modern(entry)
	vim.opt.background = entry.background
	local ok, err = pcall(vim.cmd, "colorscheme " .. entry.name)
	if not ok then
		vim.notify("[chromatic] Failed to apply '" .. entry.name .. "': " .. tostring(err), vim.log.levels.WARN)
		return false
	end
	return true
end

--- Sync lualine theme to "auto" so it tracks the new colorscheme.
local function sync_lualine()
	local ok, ll = pcall(require, "lualine")
	if ok then
		pcall(ll.setup, { options = { theme = "auto" } })
	end
end

--- Send the theme-applied notification according to config.notify.
---@param name string
local function announce(name)
	local cfg = state().effective_config()
	if cfg.notify == "silent" then
		return
	end
	local msg = "  Theme: " .. name
	if cfg.notify == "echo" then
		vim.api.nvim_echo({ { msg, "Normal" } }, false, {})
	else
		vim.notify(msg, vim.log.levels.INFO, { title = "Chromatic" })
	end
end

--- Build the filtered candidate list respecting state + config.
---@return table[], table  candidates, effective_config
local function build_candidates()
	local cfg = state().effective_config()
	local pool = registry().installed()

	-- Filter by allowlist
	if cfg.allowlist and #cfg.allowlist > 0 then
		local allowed = {}
		for _, entry in ipairs(pool) do
			if vim.tbl_contains(cfg.allowlist, entry.name) then
				table.insert(allowed, entry)
			end
		end
		pool = allowed
	end

	-- Filter by mode
	if cfg.mode then
		pool = vim.tbl_filter(function(e)
			return e.background == cfg.mode
		end, pool)
	end

	return pool, cfg
end

--- Core selection + application logic.
---@param candidates table[]
---@param cfg        table
---@param force_new  boolean  true = always randomise (ignore persist)
local function pick_and_apply(candidates, cfg, force_new)
	if #candidates == 0 then
		vim.notify("[chromatic] No eligible themes found. Falling back to: " .. cfg.fallback, vim.log.levels.WARN)
		pcall(vim.cmd, "colorscheme " .. cfg.fallback)
		return
	end

	local chosen

	-- Persist: replay last theme if it's still in the candidate list
	if not force_new and cfg.persist then
		local last = state().get("last_theme")
		if last then
			for _, e in ipairs(candidates) do
				if e.name == last then
					chosen = e
					break
				end
			end
		end
	end

	-- Random selection
	if not chosen then
		math.randomseed(os.time())
		chosen = candidates[math.random(#candidates)]
	end

	-- Load the plugin if needed
	lazy_load(chosen.plugin)

	-- Apply (legacy path or modern path)
	local ok
	if chosen.legacy then
		ok = compat().apply_legacy(chosen.name, chosen)
	else
		ok = apply_modern(chosen)
	end
	if not ok then
		return
	end

	-- Post-apply bookkeeping
	_current = chosen.name
	_applied = true

	if cfg.sync_lualine then
		sync_lualine()
	end
	if cfg.persist then
		state().set("last_theme", chosen.name)
	end
	announce(chosen.name)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- ColorScheme autocmd — stay in sync with manual :colorscheme calls
-- ─────────────────────────────────────────────────────────────────────────────
vim.api.nvim_create_autocmd("ColorScheme", {
	group = vim.api.nvim_create_augroup("ChromaticSync", { clear = true }),
	callback = function(ev)
		_current = ev.match
		_applied = true
		local cfg = state().effective_config()
		if cfg.persist then
			state().set("last_theme", ev.match)
		end
		if cfg.sync_lualine then
			sync_lualine()
		end
	end,
})

-- ─────────────────────────────────────────────────────────────────────────────
-- Public API
-- ─────────────────────────────────────────────────────────────────────────────

--- Configure the plugin. Should be called once from the user's lazy.nvim `opts`
--- or an explicit setup() call. Safe to call multiple times (last call wins).
---@param opts table|nil
function M.setup(opts)
	require("chromatic.config").apply(opts)
end

--- Primary startup entry point. Called by plugin/chromatic.lua on VimEnter.
function M.apply()
	prime_colorscheme_paths()
	local cfg = state().effective_config()

	if not cfg.enabled then
		pcall(vim.cmd, "colorscheme " .. cfg.fallback)
		_applied = true
		return
	end

	local candidates, cfg2 = build_candidates()
	pick_and_apply(candidates, cfg2, false)
end

--- Idempotent guard. Only calls apply() if no theme has been set this session.
function M.ensure_applied()
	if not _applied then
		M.apply()
	end
end

--- Pick and apply a brand-new random theme right now (always ignores persist).
function M.next()
	local candidates, cfg = build_candidates()
	pick_and_apply(candidates, cfg, true)
end

--- Return the name of the currently active colorscheme.
---@return string
function M.current()
	return _current or vim.g.colors_name or "unknown"
end

--- Return the current filtered candidate list.
---@return table[]
function M.list_available()
	return (build_candidates())
end

--- Set the background mode filter and persist it.
---@param mode "dark"|"light"|nil
function M.set_mode(mode)
	state().set("mode", mode == nil and "nil" or mode)
	vim.notify("[chromatic] Mode → " .. (mode or "any"), vim.log.levels.INFO, { title = "Chromatic" })
end

--- Toggle the persist setting and persist it.
---@param value boolean
function M.set_persist(value)
	state().set("persist", value)
	vim.notify("[chromatic] Persist → " .. tostring(value), vim.log.levels.INFO, { title = "Chromatic" })
end

return M
