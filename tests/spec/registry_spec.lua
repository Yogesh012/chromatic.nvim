-- tests/spec/registry_spec.lua
-- Tests for lua/chromatic/registry.lua

local registry
local config

local function reload()
  package.loaded["chromatic.registry"] = nil
  package.loaded["chromatic.config"]   = nil
  config   = require("chromatic.config")
  config.apply({})   -- reset to defaults (extra_themes = {})
  registry = require("chromatic.registry")
end

describe("chromatic.registry", function()

  before_each(reload)

  -- ── catalog integrity ────────────────────────────────────────────────────────

  describe("catalog", function()
    it("every entry has a non-empty name string", function()
      for _, e in ipairs(registry.catalog) do
        assert.is_string(e.name)
        assert.truthy(e.name ~= "")
      end
    end)

    it("every entry has background 'dark' or 'light'", function()
      for _, e in ipairs(registry.catalog) do
        assert.truthy(
          e.background == "dark" or e.background == "light",
          ("entry '%s' has invalid background '%s'"):format(e.name, tostring(e.background))
        )
      end
    end)

    it("contains at least one dark and one light theme", function()
      local dark, light = false, false
      for _, e in ipairs(registry.catalog) do
        if e.background == "dark"  then dark  = true end
        if e.background == "light" then light = true end
      end
      assert.is_true(dark,  "no dark themes in catalog")
      assert.is_true(light, "no light themes in catalog")
    end)

    it("has no duplicate effective keys in catalog", function()
      local seen = {}
      for _, e in ipairs(registry.catalog) do
        local key = e._key or e.name
        assert.is_nil(seen[key],
          ("duplicate key '%s' found in catalog"):format(key))
        seen[key] = true
      end
    end)
  end)

  -- ── all() ────────────────────────────────────────────────────────────────────

  describe("all()", function()
    it("returns the built-in catalog when extra_themes is empty", function()
      local all = registry.all()
      assert.equals(#registry.catalog, #all)
    end)

    it("appends extra_themes to the catalog", function()
      config.apply({
        extra_themes = {
          { name = "my-theme", background = "dark", plugin = "my-theme.nvim" },
        },
      })
      local all = registry.all()
      assert.equals(#registry.catalog + 1, #all)
      assert.equals("my-theme", all[#all].name)
    end)

    it("does not mutate the base catalog when extra_themes are added", function()
      local before = #registry.catalog
      config.apply({
        extra_themes = {
          { name = "extra", background = "light", plugin = nil },
        },
      })
      registry.all()  -- call but discard
      assert.equals(before, #registry.catalog)
    end)
  end)

  -- ── find() ───────────────────────────────────────────────────────────────────

  describe("find()", function()
    it("returns the correct entry for a known name", function()
      local entry = registry.find("gruvbox")
      assert.is_table(entry)
      assert.equals("gruvbox", entry.name)
      assert.equals("dark",    entry.background)
    end)

    it("returns nil for an unknown name", function()
      assert.is_nil(registry.find("this-theme-does-not-exist-xyz"))
    end)
  end)

  -- ── installed() ──────────────────────────────────────────────────────────────

  describe("installed()", function()
    it("always includes built-in (plugin=nil) entries", function()
      -- Built-ins like 'desert', 'slate' have plugin=nil → always present.
      local installed = registry.installed()
      local found_builtin = false
      for _, e in ipairs(installed) do
        if e.plugin == nil then
          found_builtin = true
          break
        end
      end
      assert.is_true(found_builtin, "no built-in (plugin=nil) entries in installed()")
    end)

    it("deduplicates entries that share an effective key", function()
      -- 'everforest' dark and light have _key to disambiguate,
      -- but neither should appear twice in installed().
      local installed = registry.installed()
      local seen = {}
      for _, e in ipairs(installed) do
        local key = e._key or e.name
        assert.is_nil(seen[key],
          ("duplicate key '%s' in installed()"):format(key))
        seen[key] = true
      end
    end)

    it("does not include plugin themes whose plugin is not detected", function()
      -- In a headless test env with no plugins loaded, the only installed
      -- entries should be built-ins (plugin=nil).
      -- Lazy.nvim is not available → falls back to rtp color detection.
      -- Override getcompletion to return empty list (no plugins in rtp).
      local orig = vim.fn.getcompletion
      vim.fn.getcompletion = function() return {} end

      package.loaded["chromatic.registry"] = nil
      local r2 = require("chromatic.registry")
      local installed = r2.installed()

      vim.fn.getcompletion = orig  -- restore

      for _, e in ipairs(installed) do
        assert.is_nil(e.plugin,
          ("plugin theme '%s' appears installed but shouldn't"):format(e.name))
      end
    end)

    it("includes themes detected via rtp fallback (getcompletion)", function()
      -- Simulate a non-lazy setup where getcompletion returns some color names.
      local orig = vim.fn.getcompletion
      vim.fn.getcompletion = function() return { "gruvbox", "onedark" } end

      package.loaded["chromatic.registry"] = nil
      local r2 = require("chromatic.registry")
      local installed = r2.installed()

      vim.fn.getcompletion = orig

      local names = {}
      for _, e in ipairs(installed) do names[e.name] = true end
      assert.is_true(names["gruvbox"],  "gruvbox should appear via rtp fallback")
      assert.is_true(names["onedark"], "onedark should appear via rtp fallback")
    end)
  end)

end)
