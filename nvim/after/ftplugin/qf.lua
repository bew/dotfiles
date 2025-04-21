local jump_to_current = [[<cr>zz<C-w>p]]
toplevel_buf_map{mode="n", key="o", action=jump_to_current, desc="Jump to current, stay in qf"}
toplevel_buf_map{mode="n", key="<M-j>", action="j"..jump_to_current, desc="Jump to next, stay in qf"}
toplevel_buf_map{mode="n", key="<M-k>", action="k"..jump_to_current, desc="Jump to prev, stay in qf"}

toplevel_buf_map{mode="n", key="<M-o>", action="<cr>"}

toplevel_buf_map{mode="n", key="q", action=vim.cmd.quit, desc="Quick quit qf"}
toplevel_buf_map{mode="n", key="<M-q>", action="q", desc="Record macro"}

my_actions.qf_switch_to_older = mk_action_v2 {
  default_desc = "Switch to older qf",
  n = function()
    local qf_current_nr = vim.fn.getqflist{nr=0}.nr
    print("DEBUG", "current nr:", qf_current_nr)
    if qf_current_nr == 1 then
      vim.notify("Already at oldest quickfix list!", vim.log.levels.INFO)
    else
      vim.cmd.colder()
    end
  end,
}
my_actions.qf_switch_to_newer = mk_action_v2 {
  default_desc = "Switch to newer qf",
  n = function()
    local qf_stack_size = vim.fn.getqflist{nr="$"}.nr
    local qf_current_nr = vim.fn.getqflist{nr=0}.nr
    print("DEBUG", "stack size:", qf_stack_size, "current nr:", qf_current_nr)
    if qf_current_nr == qf_stack_size then
      vim.notify("Already at newest quickfix list!", vim.log.levels.INFO)
    else
      vim.cmd.cnewer()
    end
  end,
}

toplevel_buf_map{mode="n", key="<C-o>", action=my_actions.qf_switch_to_older}
toplevel_buf_map{mode="n", key="<C-i>", action=my_actions.qf_switch_to_newer}
