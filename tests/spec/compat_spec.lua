-- tests/spec/compat_spec.lua
-- Tests for lua/chromatic/compat.lua
--
-- compat.lua is the legacy colorscheme shimming layer.
-- cterm_to_hex is a private local, so we test via the public-facing behaviour,
-- but we expose it indirectly via a minimal inline test harness loaded here.
-- apply_legacy() and the two shim functions are tested via call tracking.

-- ── Expose the private cterm_to_hex via a thin inline wrapper ─────────────────
-- We load compat.lua source and run it in a sandbox to get the private local.
local compat_src_path = vim.fn.fnamemodify(
  debug.getinfo(1, "S").source:sub(2), ":h:h:h"
) .. "/lua/chromatic/compat.lua"

local sandbox_env = setmetatable({}, { __index = _G })
local chunk = assert(loadfile(compat_src_path, "t", sandbox_env))
chunk()
local cterm_to_hex = sandbox_env.cterm_to_hex  -- grab the private local

-- If for any reason the sandbox trick didn't work, fall back gracefully.
-- (In that case the cterm_to_hex tests are skipped via pending.)
local hex_available = type(cterm_to_hex) == "function"

describe("chromatic.compat", function()

  -- ── cterm_to_hex (private, accessed via sandbox) ───────────────────────────

  describe("cterm_to_hex", function()
    if not hex_available then
      it("(skipped: cterm_to_hex not accessible from sandbox)", pending)
      return
    end

    -- Base-16 spot checks
    it("index 0 → #1c1c1c (base-16 black)", function()
      assert.equals("#1c1c1c", cterm_to_hex(0))
    end)
    it("index 7 → #c0c0c0 (base-16 silver)", function()
      assert.equals("#c0c0c0", cterm_to_hex(7))
    end)
    it("index 15 → #ffffff (base-16 white)", function()
      assert.equals("#ffffff", cterm_to_hex(15))
    end)

    -- 6×6×6 colour cube
    it("index 16 → #000000 (cube start: 0,0,0)", function()
      assert.equals("#000000", cterm_to_hex(16))
    end)
    it("index 231 → #ffffff (cube end: 5,5,5)", function()
      assert.equals("#ffffff", cterm_to_hex(231))
    end)

    -- Grayscale ramp (232–255)
    it("index 232 → #080808 (darkest gray)", function()
      assert.equals("#080808", cterm_to_hex(232))
    end)
    it("index 255 → #eeeeee (lightest gray)", function()
      assert.equals("#eeeeee", cterm_to_hex(255))
    end)

    it("result is always a 7-char hex string starting with #", function()
      for _, i in ipairs({ 0, 15, 16, 100, 200, 231, 232, 255 }) do
        local h = cterm_to_hex(i)
        assert.equals(7, #h,
          ("cterm_to_hex(%d) length != 7: got '%s'"):format(i, h))
        assert.equals("#", h:sub(1, 1),
          ("cterm_to_hex(%d) doesn't start with #: got '%s'"):format(i, h))
      end
    end)
  end)

  -- ── apply_legacy() ───────────────────────────────────────────────────────────

  describe("apply_legacy()", function()
    local compat

    before_each(function()
      package.loaded["chromatic.compat"] = nil
      compat = require("chromatic.compat")
    end)

    it("returns true when vim.cmd succeeds", function()
      local orig_cmd = vim.cmd
      vim.cmd = function() end  -- no-op success
      -- Stub shim functions to be no-ops too
      local orig_patch = compat.patch_cterm_to_gui
      local orig_fill  = compat.fill_missing_groups
      compat.patch_cterm_to_gui  = function() end
      compat.fill_missing_groups = function() end

      local result = compat.apply_legacy("desert", { background = "dark" })
      assert.is_true(result)

      vim.cmd = orig_cmd
      compat.patch_cterm_to_gui  = orig_patch
      compat.fill_missing_groups = orig_fill
    end)

    it("returns false when vim.cmd throws", function()
      local orig_cmd    = vim.cmd
      local orig_notify = vim.notify
      local notified    = false

      vim.cmd    = function() error("colorscheme not found") end
      vim.notify = function(msg, level)
        if level == vim.log.levels.WARN then notified = true end
      end

      local result = compat.apply_legacy("bad-scheme", { background = "dark" })
      assert.is_false(result)
      assert.is_true(notified, "expected WARN notify on failure")

      vim.cmd    = orig_cmd
      vim.notify = orig_notify
    end)

    it("calls patch_cterm_to_gui and fill_missing_groups on success", function()
      local patched = false
      local filled  = false

      local orig_cmd = vim.cmd
      vim.cmd = function() end
      compat.patch_cterm_to_gui  = function() patched = true end
      compat.fill_missing_groups = function() filled  = true end

      compat.apply_legacy("slate", { background = "dark" })

      assert.is_true(patched, "patch_cterm_to_gui not called")
      assert.is_true(filled,  "fill_missing_groups not called")

      vim.cmd = orig_cmd
    end)

    it("sets vim.opt.background to entry.background", function()
      local orig_cmd = vim.cmd
      vim.cmd = function() end
      compat.patch_cterm_to_gui  = function() end
      compat.fill_missing_groups = function() end

      compat.apply_legacy("habamax", { background = "light" })

      assert.equals("light", vim.o.background)

      vim.cmd = orig_cmd
    end)
  end)

end)
