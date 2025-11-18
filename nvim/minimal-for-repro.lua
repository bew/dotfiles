---@diagnostic disable: missing-fields, unused-local

vim.env.LAZY_STDPATH = "/tmp/nvim-mini-repro"
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

vim.keymap.set("n", "Q", function() vim.cmd[[quit]] end, {desc="Quit neovim o/"})

-- Example minimal config for `LuaSnip`
local plugin_luasnip = {
  "L3MON4D3/LuaSnip",
  -- dir = "/full/path/to/local/plugin/clone", -- e.g. to target my own code instead of upstream
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

-- Example minimal config for `smear-cursor`
local plugin_smearcursor = {
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

-- Example minimal config for `oil.nvim`
local plugin_oil = {
  "stevearc/oil.nvim",
  config = function()
    require("oil").setup()
  end,
}

-- Example minimal config for `multicursor.nvim`
local plugin_multicursor = {
  "jake-stewart/multicursor.nvim",
  config = function()
    local mc = require("multicursor-nvim")
    mc.setup()

    vim.api.nvim_set_hl(0, "MultiCursorCursor", { reverse = true })
    vim.api.nvim_set_hl(0, "MultiCursorVisual", { link = "Visual" })
    vim.api.nvim_set_hl(0, "MultiCursorMatchPreview", { link = "Search" })

    vim.keymap.set({"n", "x"}, "<M-Space><M-j>", function() mc.lineAddCursor(1) end, {desc="Add cursor below"})
    vim.keymap.set({"n", "x"}, "<M-Space>n", function() mc.matchAddCursor(1) end, {desc="Add cursor on next match"})
    vim.keymap.set("n", "<M-Space><M-esc>", function() mc.clearCursors() end, {desc="Clear all cursors"})
  end,
}


require"lazy.minit".repro {
  spec = {
    plugin_multicursor,
  },
}
