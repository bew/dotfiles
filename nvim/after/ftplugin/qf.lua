local TERM_CODES = require"mylib.term_codes"
local A = require"mylib.action_system"
local K = require"mylib.keymap_system"
local U = require"mylib.utils"

local jump_to_current = [[<cr>zz<C-w>p]]
K.toplevel_buf_map{mode="n", key="o",     action="<cr>", desc="Jump to current"}
K.toplevel_buf_map{mode="n", key="<M-o>", action=jump_to_current, desc="Jump to current, stay in qf"}
K.toplevel_buf_map{mode="n", key="<M-j>", action="j"..jump_to_current, desc="Jump to next, stay in qf"}
K.toplevel_buf_map{mode="n", key="<M-k>", action="k"..jump_to_current, desc="Jump to prev, stay in qf"}

K.toplevel_buf_map{mode="n", key="q", action=my_actions.close_win_back_to_last}
K.toplevel_buf_map{mode="n", key="<M-q>", action="q", desc="Record macro"}

K.toplevel_buf_map{mode="n", key="<M-CR>", desc="Jump to current, close qf", action=function()
  U.feed_keys_sync(TERM_CODES.CR)
  vim.cmd.cclose()
end}

my_actions.qf_switch_to_older = A.mk_action {
  default_desc = "Switch to older qf",
  n = function()
    local qf_current_nr = vim.fn.getqflist{nr=0}.nr
    -- print("DEBUG", "current nr:", qf_current_nr)
    if qf_current_nr == 1 then
      vim.notify("Already at oldest quickfix list!", vim.log.levels.INFO)
    else
      vim.cmd.colder()
    end
  end,
}
my_actions.qf_switch_to_newer = A.mk_action {
  default_desc = "Switch to newer qf",
  n = function()
    local qf_stack_size = vim.fn.getqflist{nr="$"}.nr
    local qf_current_nr = vim.fn.getqflist{nr=0}.nr
    -- print("DEBUG", "stack size:", qf_stack_size, "current nr:", qf_current_nr)
    if qf_current_nr == qf_stack_size then
      vim.notify("Already at newest quickfix list!", vim.log.levels.INFO)
    else
      vim.cmd.cnewer()
    end
  end,
}

K.toplevel_buf_map{mode="n", key="<C-o>", action=my_actions.qf_switch_to_older}
K.toplevel_buf_map{mode="n", key="<C-i>", action=my_actions.qf_switch_to_newer}

my_actions.qf_fuzzy_entries = A.mk_action {
  default_desc = "Fuzzy qf/loc entries",
  n = function()
    local wininfo = vim.fn.getwininfo(vim.fn.win_getid())[1]
    if wininfo.loclist == 1 then
      local list_nr = vim.fn.getloclist(0, { nr = true }).nr
      require"mycfg.fuzzy_pickers".fancy_loclist { nr = list_nr }
    else
      local list_nr = vim.fn.getqflist({ nr = true }).nr
      require"mycfg.fuzzy_pickers".fancy_quickfix { nr = list_nr }
    end
  end,
}
my_actions.qf_fuzzy_old_lists = A.mk_action {
  default_desc = "Fuzzy old qf lists",
  n = function()
    require"telescope.builtin".quickfixhistory { layout_strategy = "vertical" }
  end,
}
K.toplevel_buf_map{mode="n", key="<M-/>", action=my_actions.qf_fuzzy_entries}
K.local_leader_buf_map{mode="n", key="qf", action=my_actions.qf_fuzzy_entries}
K.local_leader_buf_map{mode="n", key="qh", action=my_actions.qf_fuzzy_old_lists}
