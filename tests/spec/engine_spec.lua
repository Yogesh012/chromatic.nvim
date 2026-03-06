-- tests/spec/engine_spec.lua
-- Tests for lua/chromatic/init.lua (core engine + public API)

local engine
local config
local state

local function reload_all()
  -- Clear the entire chromatic module tree so each test starts fresh.
  for k in pairs(package.loaded) do
    if k:match("^chromatic") then
      package.loaded[k] = nil
    end
  end
  config = require("chromatic.config")
  state  = require("chromatic.state")
  state.reset()
end

local function load_engine()
  package.loaded["chromatic"] = nil
  -- The engine module fires a ColorScheme autocmd at load time; that's fine
  -- in headless mode — Neovim accepts it silently.
  engine = require("chromatic")
end

describe("chromatic (engine)", function()

  before_each(function()
    reload_all()
    -- Stub vim.cmd so :colorscheme calls don't actually switch themes.
    _G._orig_vim_cmd = vim.cmd
    vim.cmd = function() end

    _G._orig_vim_notify = vim.notify
    vim.notify = function() end

    load_engine()
  end)

  after_each(function()
    vim.cmd    = _G._orig_vim_cmd
    vim.notify = _G._orig_vim_notify
    reload_all()
  end)

  -- ── setup() ─────────────────────────────────────────────────────────────────

  describe("setup()", function()
    it("delegates to config.apply()", function()
      engine.setup({ notify = "echo", persist = true })
      local cfg = require("chromatic.config").get()
      assert.equals("echo", cfg.notify)
      assert.equals(true,   cfg.persist)
    end)

    it("accepts nil opts without error", function()
      assert.has_no_error(function() engine.setup(nil) end)
    end)
  end)

  -- ── current() ───────────────────────────────────────────────────────────────

  describe("current()", function()
    it("returns vim.g.colors_name when no theme applied yet", function()
      vim.g.colors_name = "habamax"
      assert.equals("habamax", engine.current())
    end)

    it("returns 'unknown' when colors_name is not set", function()
      vim.g.colors_name = nil
      -- Reload engine so _current is nil.
      package.loaded["chromatic"] = nil
      local fresh = require("chromatic")
      assert.equals("unknown", fresh.current())
    end)
  end)

  -- ── list_available() ────────────────────────────────────────────────────────

  describe("list_available()", function()
    it("returns a table", function()
      config.apply({})
      assert.is_table(engine.list_available())
    end)

    it("respects mode='dark' filter — only dark themes", function()
      config.apply({ mode = "dark" })
      for _, e in ipairs(engine.list_available()) do
        assert.equals("dark", e.background,
          ("non-dark theme '%s' in dark-mode list"):format(e.name))
      end
    end)

    it("respects mode='light' filter — only light themes", function()
      config.apply({ mode = "light" })
      for _, e in ipairs(engine.list_available()) do
        assert.equals("light", e.background,
          ("non-light theme '%s' in light-mode list"):format(e.name))
      end
    end)

    it("respects allowlist — only allowlisted themes", function()
      config.apply({ allowlist = { "desert", "slate" } })
      local avail = engine.list_available()
      for _, e in ipairs(avail) do
        assert.truthy(
          e.name == "desert" or e.name == "slate",
          ("unexpected theme '%s' outside allowlist"):format(e.name)
        )
      end
    end)
  end)

  -- ── apply() ─────────────────────────────────────────────────────────────────

  describe("apply()", function()
    it("calls vim.cmd with fallback when enabled=false", function()
      config.apply({ enabled = false, fallback = "desert" })
      local called_with = nil
      vim.cmd = function(c) called_with = c end
      engine.apply()
      assert.truthy(
        called_with and called_with:find("desert"),
        "expected 'colorscheme desert', got: " .. tostring(called_with)
      )
    end)

    it("calls vim.cmd with a valid theme name when enabled=true", function()
      -- Only built-in (plugin=nil) themes will be in the candidate list
      -- in headless mode with no plugins loaded.
      config.apply({ enabled = true })
      local called_with = nil
      vim.cmd = function(c) called_with = c end
      engine.apply()
      assert.truthy(
        called_with and called_with:match("^colorscheme "),
        "expected 'colorscheme <name>', got: " .. tostring(called_with)
      )
    end)

    it("shows WARN notify when no candidates match", function()
      -- Use an allowlist that matches no installed themes.
      config.apply({ allowlist = { "this-theme-xyz-does-not-exist" } })
      local warned = false
      vim.notify = function(_, level)
        if level == vim.log.levels.WARN then warned = true end
      end
      engine.apply()
      assert.is_true(warned, "expected WARN notification when no candidates found")
    end)
  end)

  -- ── next() ──────────────────────────────────────────────────────────────────

  describe("next()", function()
    it("calls vim.cmd with a colorscheme command", function()
      config.apply({ enabled = true })
      local called = false
      vim.cmd = function(c)
        if type(c) == "string" and c:match("^colorscheme ") then
          called = true
        end
      end
      engine.next()
      assert.is_true(called, "next() did not call vim.cmd with colorscheme")
    end)
  end)

  -- ── set_mode() / set_persist() ──────────────────────────────────────────────

  describe("set_mode()", function()
    it("persists 'dark' to state", function()
      engine.set_mode("dark")
      assert.equals("dark", state.get("mode"))
    end)

    it("persists 'light' to state", function()
      engine.set_mode("light")
      assert.equals("light", state.get("mode"))
    end)

    it("persists nil as the string 'nil' to state", function()
      engine.set_mode(nil)
      assert.equals("nil", state.get("mode"))
    end)
  end)

  describe("set_persist()", function()
    it("persists true to state", function()
      engine.set_persist(true)
      assert.equals(true, state.get("persist"))
    end)

    it("persists false to state", function()
      engine.set_persist(false)
      assert.equals(false, state.get("persist"))
    end)
  end)

end)
