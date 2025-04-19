---@diagnostic disable: missing-fields

vim.env.LAZY_STDPATH = "/tmp/nvim-mini-repro"
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

-- Example minimal config for LuaSnip
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

require("lazy.minit").repro { spec = plugin_specs_luasnip }
