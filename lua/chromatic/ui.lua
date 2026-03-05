--- chromatic/ui.lua
--- User-facing Neovim commands for the chromatic.nvim plugin.
---
--- Commands registered (all via plugin/chromatic.lua → ui.setup()):
---   :ChromaticNext           pick a new random theme immediately
---   :ChromaticMode <mode>    set dark / light / any (persisted to state.json)
---   :ChromaticConfig         interactive vim.ui.select settings picker
---   :ChromaticInfo           print current theme name + active settings

local M = {}

local function engine() return require("chromatic") end
local function state()  return require("chromatic.state") end

function M.setup()
  -- :ChromaticNext
  vim.api.nvim_create_user_command("ChromaticNext", function()
    engine().next()
  end, { desc = "Chromatic: pick a new random theme" })

  -- :ChromaticMode [dark|light|any]
  vim.api.nvim_create_user_command("ChromaticMode", function(opts)
    local arg = (opts.args or ""):lower()
    if     arg == "dark"         then engine().set_mode("dark")
    elseif arg == "light"        then engine().set_mode("light")
    elseif arg == "any" or arg == "" then engine().set_mode(nil)
    else
      vim.notify("[chromatic] Unknown mode '" .. arg .. "'. Use: dark | light | any",
        vim.log.levels.WARN)
    end
  end, {
    nargs    = "?",
    complete = function() return { "dark", "light", "any" } end,
    desc     = "Chromatic: set background mode filter",
  })

  -- :ChromaticInfo
  vim.api.nvim_create_user_command("ChromaticInfo", function()
    local cfg  = state().effective_config()
    local cur  = engine().current()
    vim.notify(
      table.concat({
        "  Current   : " .. cur,
        "  Mode      : " .. (cfg.mode or "any"),
        "  Persist   : " .. tostring(cfg.persist),
        "  Allowlist : " .. (#cfg.allowlist > 0 and table.concat(cfg.allowlist, ", ") or "all"),
      }, "\n"),
      vim.log.levels.INFO,
      { title = "Chromatic" }
    )
  end, { desc = "Chromatic: show current theme and settings" })

  -- :ChromaticConfig  (interactive picker)
  vim.api.nvim_create_user_command("ChromaticConfig", function()
    local cfg = state().effective_config()
    local items = {
      "Set mode → dark",
      "Set mode → light",
      "Set mode → any (no filter)",
      "Toggle persist  (currently: " .. tostring(cfg.persist) .. ")",
      "Pick a new random theme now",
      "Reset all settings to defaults",
    }
    vim.ui.select(items, {
      prompt = "Chromatic — Settings",
      format_item = function(i) return "  " .. i end,
    }, function(choice)
      if not choice then return end
      if     choice:find("mode → dark")    then engine().set_mode("dark")
      elseif choice:find("mode → light")   then engine().set_mode("light")
      elseif choice:find("mode → any")     then engine().set_mode(nil)
      elseif choice:find("Toggle persist") then engine().set_persist(not cfg.persist)
      elseif choice:find("Pick a new")     then engine().next()
      elseif choice:find("Reset all")      then
        state().reset()
        vim.notify("[chromatic] Settings reset to defaults.", vim.log.levels.INFO,
          { title = "Chromatic" })
      end
    end)
  end, { desc = "Chromatic: interactive settings picker" })
end

return M
