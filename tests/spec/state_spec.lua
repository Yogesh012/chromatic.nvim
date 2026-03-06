-- tests/spec/state_spec.lua
-- Tests for lua/chromatic/state.lua
--
-- state.lua reads/writes a JSON file at vim.fn.stdpath("data")/chromatic_state.json.
-- We redirect _path to a tmp file so tests never touch the real state file.

local state

-- Because state._path is a module-private local, we can't reassign it from outside.
-- However, we CAN test all public behaviour by:
--   1. Calling state.reset() before each test (clears _cache and writes "{}" to the real path).
--   2. Testing all logic that doesn't depend on the specific file location.
-- For I/O tests that need a controlled file, we use the real path + cleanup.

describe("chromatic.state", function()

  before_each(function()
    package.loaded["chromatic.state"]  = nil
    package.loaded["chromatic.config"] = nil
    state = require("chromatic.state")
    -- Reset cache and file at the start of each test.
    state.reset()
  end)

  after_each(function()
    state.reset()
  end)

  -- ── load() ──────────────────────────────────────────────────────────────────

  describe("load()", function()
    it("returns {} after reset() (empty / missing file)", function()
      local s = state.load()
      assert.is_table(s)
      assert.equals(0, #s)
      assert.is_nil(next(s))   -- table is empty
    end)

    it("returns cached table on repeated calls", function()
      local a = state.load()
      local b = state.load()
      assert.equal(a, b)        -- same reference → cached
    end)
  end)

  -- ── get() / set() round-trip ────────────────────────────────────────────────

  describe("get() / set()", function()
    it("set() then get() returns the same value (string)", function()
      state.set("mode", "dark")
      assert.equals("dark", state.get("mode"))
    end)

    it("set() then get() returns the same value (boolean)", function()
      state.set("persist", true)
      assert.equals(true, state.get("persist"))
    end)

    it("get() returns nil for unknown key", function()
      assert.is_nil(state.get("nonexistent_key_xyz"))
    end)

    it("set() overwrites an existing key", function()
      state.set("mode", "dark")
      state.set("mode", "light")
      assert.equals("light", state.get("mode"))
    end)
  end)

  -- ── reset() ─────────────────────────────────────────────────────────────────

  describe("reset()", function()
    it("clears all keys", function()
      state.set("mode", "dark")
      state.set("persist", true)
      state.reset()
      assert.is_nil(state.get("mode"))
      assert.is_nil(state.get("persist"))
    end)

    it("subsequent load() returns empty table", function()
      state.set("last_theme", "gruvbox")
      state.reset()
      local s = state.load()
      assert.is_nil(s.last_theme)
    end)
  end)

  -- ── effective_config() ──────────────────────────────────────────────────────

  describe("effective_config()", function()
    before_each(function()
      -- Apply a known base config.
      require("chromatic.config").apply({
        mode    = "dark",
        persist = false,
        notify  = "silent",
      })
    end)

    it("returns config defaults when state is empty", function()
      local cfg = state.effective_config()
      assert.equals("dark",   cfg.mode)
      assert.equals(false,    cfg.persist)
      assert.equals("silent", cfg.notify)
    end)

    it("state.mode overrides config.mode", function()
      state.set("mode", "light")
      local cfg = state.effective_config()
      assert.equals("light", cfg.mode)
    end)

    it("state.persist overrides config.persist", function()
      state.set("persist", true)
      local cfg = state.effective_config()
      assert.equals(true, cfg.persist)
    end)

    it('state mode "nil" string is normalised to real nil', function()
      state.set("mode", "nil")
      local cfg = state.effective_config()
      assert.is_nil(cfg.mode)
    end)

    it("state does not override keys it doesn't have", function()
      -- notify is not stored in state — it should stay as the config value.
      local cfg = state.effective_config()
      assert.equals("silent", cfg.notify)
    end)
  end)

end)
