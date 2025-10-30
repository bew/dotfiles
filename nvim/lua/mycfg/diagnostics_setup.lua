
local A = require"mylib.action_system"
local K = require"mylib.keymap_system"

vim.diagnostic.config {
  -- Show higher severities _before_ lower ones (e.g. ERROR is displayed before WARN)
  severity_sort = true,
  -- Disable signs in the gutter
  -- They are annoying when a line has 2+ diagnostics as other signs (like git) are overwriten..
  signs = false,
  -- Show diagnostic for all lines as virtual text
  -- note: can be toggle for all lines / only current line with the action below
  virtual_text = {}, -- note: using `{}` instead of `true` for edition in toggle action
}

my_actions.toggle_diag_virtual_text_mode = A.mk_action {
  default_desc = "Toggle diagnostic virtual_text mode: all lines / current line",
  n = function()
    local diag_config = vim.diagnostic.config()
    ---@cast diag_config vim.diagnostic.Opts (known to be not nil!)
    diag_config.virtual_text.current_line = not diag_config.virtual_text.current_line
    vim.diagnostic.config(diag_config)
    local new_mode_name = diag_config.virtual_text.current_line and "current line" or "all lines"
    vim.notify("Diagnostic virtual text mode: " .. new_mode_name)
  end
}

---@class mycfg.diag.GotoDiagBySevArgs
---@field get_diag_pos_fn fun(opts?: vim.diagnostic.JumpOpts)
---@field jump_opts vim.diagnostic.JumpOpts

-- note: `NOTE` severity level is ignored, as they usually are attached to another diagnostic and
--   don't have much value on their own.
local severity_layers = {
  vim.diagnostic.severity.ERROR,
  vim.diagnostic.severity.WARN,
  vim.diagnostic.severity.HINT,
}

-- IDEA: make this option scoped per-win or per-buf ?
-- TODO: Have a proper way to define option, with type, display name, tag/scope, toggle/cycle/.. action, ..
-- TODO: Have a way to show current option(s) value(s) by tag/scope
if vim.g.mycfg_option_navigate_diagnostics_in_severity_layers == nil then
  vim.g.mycfg_option_navigate_diagnostics_in_severity_layers = true
end
my_actions.toggle_diag_navigation_by_severity_layers = A.mk_action {
  default_desc = "Toggle diagnostic nav: any / by severity layers",
  n = function()
    local new_value = not vim.g.mycfg_option_navigate_diagnostics_in_severity_layers
    vim.g.mycfg_option_navigate_diagnostics_in_severity_layers = new_value
    local new_mode_name = new_value and "jump by severity layers" or "jump to any severity"
    vim.notify("Diagnostic navigation: " .. new_mode_name, vim.log.levels.INFO)
  end
}

--- Jump to next/prev diagnostic by layer of severity.
--- Search for ERROR severity, if none search for WARN severity, if none search for HINT severity.
---@param args mycfg.diag.GotoDiagBySevArgs
local function goto_diag_by_severity_layers(args)
  local jump_opts = args.jump_opts
  for _, severity in ipairs(severity_layers) do
    -- note: need to copy opts before passing to vim.diagnostic functions, as their impl will
    --   overwrite the cursor position, which gives wrong pos for next severity check.
    jump_opts.severity = vim.diagnostic.severity[severity]
    if args.get_diag_pos_fn(vim.deepcopy(jump_opts)) then
      -- There is a diagnostic for this severity, jump to it
      vim.diagnostic.jump(vim.deepcopy(jump_opts))
      return
    end
    -- otherwise, check the next severity..
    -- vim.notify("no more diag with severity "..severity..", checking next..", vim.log.levels.DEBUG) -- DEBUG
  end
  vim.notify("Zero diagnostics left 👍", vim.log.levels.INFO)
end

my_actions.goto_next_diag = A.mk_action {
  default_desc = "Go to next diagnostic (by severity)",
  n = function()
    local jump_opts = {
      float = true, -- open float after jump
      count = 1, -- next
    }
    if vim.g.mycfg_option_navigate_diagnostics_in_severity_layers then
      goto_diag_by_severity_layers {
        get_diag_pos_fn = vim.diagnostic.get_next,
        jump_opts = jump_opts, -- next
      }
    else
      vim.diagnostic.jump(jump_opts)
    end
  end,
}

my_actions.goto_prev_diag = A.mk_action {
  default_desc = "Go to prev diagnostic (by severity)",
  n = function()
    local jump_opts = {
      float = true, -- open float after jump
      count = -1, -- previous
    }
    if vim.g.mycfg_option_navigate_diagnostics_in_severity_layers then
      goto_diag_by_severity_layers {
        get_diag_pos_fn = vim.diagnostic.get_prev,
        jump_opts = jump_opts,
      }
    else
      vim.diagnostic.jump(jump_opts)
    end
  end,
}

my_actions.goto_next_diag_diff_line = A.mk_action {
  default_desc = "Go to next diagnostic (by severity, != line)",
  n = function()
    local jump_opts = {
      float = true, -- open float after jump
      count = 1, -- next
      -- Start searching from next line
      pos = { --[[ row1 ]] vim.fn.line"." +1, --[[ col0 ]] 0 },
    }
    if vim.g.mycfg_option_navigate_diagnostics_in_severity_layers then
      goto_diag_by_severity_layers {
        get_diag_pos_fn = vim.diagnostic.get_next,
        jump_opts = jump_opts,
      }
    else
      vim.diagnostic.jump(jump_opts)
    end
  end,
}

my_actions.goto_prev_diag_diff_line = A.mk_action {
  default_desc = "Go to prev diagnostic (by severity, != line)",
  n = function()
    local jump_opts = {
      float = true, -- open float after jump
      count = -1, -- previous
      -- Start searching from prev line
      pos = { --[[ row1 ]] vim.fn.line"." -1, --[[ col0 ]] 0 },
    }
    if vim.g.mycfg_option_navigate_diagnostics_in_severity_layers then
      goto_diag_by_severity_layers {
        get_diag_pos_fn = vim.diagnostic.get_prev,
        jump_opts = jump_opts,
      }
    else
      vim.diagnostic.jump(jump_opts)
    end
  end,
}

my_actions.fuzzy_buf_diags = A.mk_action {
  default_desc = "Fuzzy buf diagnostics",
  n = function()
    require"telescope.builtin".diagnostics {
      bufnr = 0,
      layout_strategy = "vertical",
    }
  end,
}
my_actions.fuzzy_all_diags = A.mk_action {
  default_desc = "Fuzzy all diagnostics",
  n = function()
    require"telescope.builtin".diagnostics {
      layout_strategy = "vertical",
    }
  end,
}

my_actions.qf_buf_diags = A.mk_action {
  default_desc = "Set qf with buf diagnostics",
  n = function()
    vim.diagnostic.setloclist { title = "Buffer Diagnostics" }
  end,
}

my_actions.qf_all_diags = A.mk_action {
  default_desc = "Set qf with all diagnostics",
  n = function()
    vim.diagnostic.setqflist { title = "All Diagnostics" }
  end,
}

my_actions.qf_buf_diags_by_severity = A.mk_action {
  default_desc = "Set qf with buf diagnostics",
  n = function()
    local diags = {}
    for _, sev in ipairs(severity_layers) do
      vim.list_extend(diags, vim.diagnostic.get(0, { severity = sev }))
    end
    local items = vim.diagnostic.toqflist(diags)
    vim.fn.setloclist(0, {}, --[[make new one!]]" ", {
      title = "Buffer Diagnostics (by severity)",
      items = items,
    })
    vim.cmd.lopen()
  end,
}

my_actions.qf_all_diags_by_severity = A.mk_action {
  default_desc = "Set qf with all diagnostics",
  n = function()
    local diags = {}
    for _, sev in ipairs(severity_layers) do
      vim.list_extend(diags, vim.diagnostic.get(--[[all!]]nil, { severity = sev }))
    end
    local items = vim.diagnostic.toqflist(diags)
    vim.fn.setqflist({}, --[[make new one!]]" ", {
      title = "All Diagnostics (by severity)",
      items = items,
    })
    vim.cmd.copen()
  end,
}

K.local_leader_map_define_group{mode={"n"}, prefix_key="d", name="+diagnostics"}
K.local_leader_map{mode="n", key="dd", desc="Show diagnostics in popup", action=vim.diagnostic.open_float}
K.local_leader_map{mode="n", key="dn", action=my_actions.goto_next_diag}
K.local_leader_map{mode="n", key="dp", action=my_actions.goto_prev_diag}
K.local_leader_map{mode="n", key="dj", action=my_actions.goto_next_diag_diff_line}
K.local_leader_map{mode="n", key="dk", action=my_actions.goto_prev_diag_diff_line}
K.local_leader_map{mode="n", key="df", action=my_actions.fuzzy_buf_diags}
K.local_leader_map{mode="n", key="dF", action=my_actions.fuzzy_all_diags}
K.local_leader_map{mode="n", key="dq", action=my_actions.qf_buf_diags_by_severity}
K.local_leader_map{mode="n", key="dQ", action=my_actions.qf_all_diags_by_severity}

K.local_leader_map_define_group{mode={"n"}, prefix_key="do", name="+options"}
K.local_leader_map{mode="n", key="dol", action=my_actions.toggle_diag_virtual_text_mode}
K.local_leader_map{mode="n", key="dos", action=my_actions.toggle_diag_navigation_by_severity_layers}
