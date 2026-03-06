-- tests/spec/config_spec.lua
-- Tests for lua/chromatic/config.lua
--
-- Run locally:
--   nvim --headless -u tests/init.lua -c "lua require('busted.runner')()" -- tests/spec/config_spec.lua

local config

-- Reset module state between tests so _config doesn't bleed across cases.
local function reload()
  package.loaded["chromatic.config"] = nil
  config = require("chromatic.config")
end

describe("chromatic.config", function()

  before_each(function()
    reload()
  end)

  -- ── defaults ────────────────────────────────────────────────────────────────

  describe("defaults", function()
    it("has all expected keys", function()
      local d = config.defaults
      assert.is_boolean(d.enabled)
      assert.is_string(d.fallback)
      assert.is_nil(d.mode)
      assert.is_table(d.allowlist)
      assert.is_table(d.extra_themes)
      assert.is_boolean(d.persist)
      assert.is_boolean(d.sync_lualine)
      assert.is_string(d.notify)
    end)

    it("enabled is true by default", function()
      assert.is_true(config.defaults.enabled)
    end)

    it("fallback is 'default'", function()
      assert.equals("default", config.defaults.fallback)
    end)

    it("persist is false by default", function()
      assert.is_false(config.defaults.persist)
    end)

    it("notify is 'notify' by default", function()
      assert.equals("notify", config.defaults.notify)
    end)
  end)

  -- ── get() ───────────────────────────────────────────────────────────────────

  describe("get()", function()
    it("returns defaults when setup() was never called", function()
      local cfg = config.get()
      assert.is_table(cfg)
      assert.equals(config.defaults.enabled,    cfg.enabled)
      assert.equals(config.defaults.fallback,   cfg.fallback)
      assert.equals(config.defaults.persist,    cfg.persist)
      assert.equals(config.defaults.sync_lualine, cfg.sync_lualine)
    end)

    it("returns a copy, not the same table reference", function()
      local cfg = config.get()
      assert.are_not_equal(config.defaults, cfg)
    end)
  end)

  -- ── apply() / setup() ───────────────────────────────────────────────────────

  describe("apply()", function()
    it("merges user opts into defaults", function()
      config.apply({ enabled = false })
      assert.is_false(config.get().enabled)
    end)

    it("does not wipe unrelated defaults when passing partial opts", function()
      config.apply({ notify = "silent" })
      local cfg = config.get()
      assert.equals("silent",  cfg.notify)
      assert.equals("default", cfg.fallback)   -- untouched
      assert.is_false(cfg.persist)             -- untouched
    end)

    it("deep-merges tables (allowlist)", function()
      config.apply({ allowlist = { "gruvbox", "tokyonight-storm" } })
      local cfg = config.get()
      assert.equals(2, #cfg.allowlist)
      assert.equals("gruvbox", cfg.allowlist[1])
    end)

    it("last call wins (idempotent override)", function()
      config.apply({ fallback = "habamax" })
      config.apply({ fallback = "desert" })
      assert.equals("desert", config.get().fallback)
    end)

    it("nil opts treated same as empty table", function()
      config.apply(nil)
      local cfg = config.get()
      assert.equals(config.defaults.enabled, cfg.enabled)
    end)
  end)

end)
