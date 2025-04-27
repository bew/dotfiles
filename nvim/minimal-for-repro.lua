---@diagnostic disable: missing-fields, unused-local

vim.env.LAZY_STDPATH = "/tmp/nvim-mini-repro"
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

-- Example minimal config for `LuaSnip`
local plugin_specs_luasnip = {
  {
    -- dir = "/full/path/to/local/plugin/clone", -- e.g. to target my own code instead of upstream
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    config = function()
      vim.keymap.set("i", [[<tab>]], function() require"luasnip".expand() end)

      -- Define snippets
      local ls = require"luasnip"
      ls.add_snippets("all", {
        ls.snippet({ trig="bad" }, { ls.insert_node(1, "é") }),
      })
    end,
  }
}

-- Example minimal config for `smear-cursor`
local plugin_specs_smearcursor = {
  {
    "sphamba/smear-cursor.nvim",
    config = function()
      require"smear_cursor".setup {
        legacy_computing_symbols_support = true,
        smear_insert_mode = false,
        smear_to_cmd = false,

        -- New default (false) looks pretty bad
        -- ISSUE: https://github.com/sphamba/smear-cursor.nvim/issues/125
        -- never_draw_over_target = true,

        trailing_stiffness = 0.07, -- DEBUG: much slower trail (0.02-0.05)
      }
    end,
  }
}

require"lazy.minit".repro { spec = plugin_specs_smearcursor }
