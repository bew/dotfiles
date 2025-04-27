local PluginSystem = require"mylib.plugin_system"
-- local t = PluginSystem.tags
local gh = PluginSystem.sources.github
local myplug = PluginSystem.sources.myplug
local Plug = PluginSystem.get_plugin_declarator {
  default_tags = { "config" },
}

local A = require"mylib.action_system"
local K = require"mylib.keymap_system"

--------------------------------

Plug {
  enabled = false, -- NOTE(DEBUG): Enable when exploring/debugging stuff
  source = myplug"debug-autocmds.nvim",
  desc = "Tool to debug/understand autocmd flow while using neovim",
  tags = {"utils", "debug"},
  on_load = function()
    require"debug-autocmds".setup{
      global_tracking_on_start = true, -- switch to `true` to debug builtin events from start :)
    }
    -- NOTE: Nice 'oneliner' to get some info about buffer/window/tab events
    -- require"debug-autocmds".get"global":dump_matching_with("buf,win,tab", function(ev) print(("%-15s"):format(ev.name), vim.fs.basename(ev.raw.file), "   tab:", ev.extra.tabnr, "   win:", ev.extra.winid) end)
    -- require"debug-autocmds".get"global":dump_matching_with("user", function(ev) print(("%-8s"):format(ev.name), ("%-15s"):format(ev.raw.file), "   data:", vim.inspect(ev.raw.data, { newline = "" })) end)
  end,
}

Plug {
  source = gh"ii14/neorepl.nvim",
  desc = "Neovim REPL for lua and vim script",
  tags = {"config"},
  defer_load = { on_event = "VeryLazy" },
  -- NOTE: use `/h` to get help inside the repl buffer
  on_load = function()
    -- NOTE: need my PR (#21) to merge config with plugin's default config
    require"neorepl".config {
      startinsert = false, -- Don't start REPL in insert mode
      indent = 4, -- Indent outputs
      on_init = function(_bufnr)
        -- Plugin comes with its own completion, so other auto-completion plugins must be disabled
        require"cmp".setup.buffer({ enabled = false })

        -- Map plugin's completion to usual completion key (Which is <Tab> here by default :/)
        K.toplevel_buf_map{mode="i", key="<C-n>", opts={expr=true}, action=function()
          return vim.fn.pumvisible() == 1 and "<C-n>" or "<Plug>(neorepl-complete)"
        end}

        -- navigate in history
        K.toplevel_buf_map{mode="i", key="<M-j>", action="<Plug>(neorepl-hist-next)"}
        K.toplevel_buf_map{mode="i", key="<M-k>", action="<Plug>(neorepl-hist-prev)"}
        K.toplevel_buf_map{mode="i", key="<Down>", action="<Plug>(neorepl-hist-next)"}
        K.toplevel_buf_map{mode="i", key="<Up>", action="<Plug>(neorepl-hist-prev)"}
        -- toplevel_buf_map{mode="i", key="<M-k>", opts={expr=true}, action=function()
        --   -- FIXME: if cursor is at top line of editable region
        --   return "<Plug>(neorepl-hist-prev)"
        --   -- FIXME: else
        --   return "<Up>"
        -- end}
        -- toplevel_buf_map{mode="i", key="<M-j>", opts={expr=true}, action=function()
        --   -- FIXME: if cursor is at bottom line of editable region
        --   return "<Plug>(neorepl-hist-next)"
        --   -- FIXME: else
        --   return "<Down>"
        -- end}

        -- N: navigate from section to sections
        K.toplevel_buf_map{mode="n", key="<M-j>", action="<Plug>(neorepl-]])"}
        K.toplevel_buf_map{mode="n", key="<M-k>", action="<Plug>(neorepl-[[)"}

        -- N,I: Eval line(s)
        K.toplevel_buf_map{mode={"n", "i"}, key="<CR>", action="<Plug>(neorepl-eval-line)"}
        K.toplevel_buf_map{mode="i", key="<C-j>", action="<Plug>(neorepl-eval-line)"}

        -- N,I: multiline editing
        K.toplevel_buf_map{mode="i", key="<M-CR>", action="<Plug>(neorepl-break-line)"}
        K.toplevel_buf_map{mode="i", key="<M-o>", action="<End><Plug>(neorepl-break-line)"}
        K.toplevel_buf_map{mode="n", key="o", action="A<Plug>(neorepl-break-line)"}
        -- FIXME: Fix detection of start of line, going to BOL of non-first line of editable area should put cursor after initial `\`
        -- toplevel_buf_map{mode="i", key="<M-O>", action="<Home><Plug>(neorepl-break-line)<Up>"}
        -- toplevel_buf_map{mode="n", key="O", action="I<Plug>(neorepl-break-line)<Up>"}

        -- I: Ctrl-d exits
        K.toplevel_buf_map{mode="i", key="<C-d>", action=function()
          if vim.api.nvim_get_current_line() == "" then
            vim.cmd.quit()
          else
            vim.notify("Cannot quit repl, line is not empty!", vim.log.levels.ERROR)
          end
        end}
      end,
    }

    my_actions.neovim_lua_repl = A.mk_action {
      default_desc = "Neovim Lua Repl buffer",
      n = "<cmd>Repl lua<cr>",
    }
    my_actions.neovim_vim_repl = A.mk_action {
      default_desc = "Neovim VimScript Repl buffer",
      n = "<cmd>Repl vim<cr>",
    }
  end,
}
