
vim.diagnostic.config {
  -- Disable signs in the gutter
  -- They are annoying when a line has 2+ diagnostics as other signs (like git) are overwriten..
  signs = false,
}
-- TODO: hide diag virtual _TEXT_ most of the time, but show colored dots only (or types of diags),
--   and only show the current line diag text (in virtual text / in cmdline / in statusline 🤔)

---@class mycfg.diag.GotoDiagBySevArgs
---@field goto_diag_fn fun(opts?: vim.diagnostic.GotoOpts)
---@field get_diag_pos_fn fun(opts?: vim.diagnostic.GotoOpts)
---@field goto_opts vim.diagnostic.GotoOpts

-- note: `NOTE` severity level is ignored, as they usually are attached to another diagnostic and
--   don't have much value on their own.
local severity_layers = {
  vim.diagnostic.severity.ERROR,
  vim.diagnostic.severity.WARN,
  vim.diagnostic.severity.HINT,
}

--- Jump to next/prev diagnostic by layer of severity.
--- Search for ERROR severity, if none search for WARN severity, if none search for HINT severity.
---@param args mycfg.diag.GotoDiagBySevArgs
local goto_diag_by_severity_layers = function(args)
  local goto_opts = args.goto_opts
  for _, severity in ipairs(severity_layers) do
    -- note: need to copy opts before passing to vim.diagnostic functions, as their impl will
    --   overwrite the cursor position, which gives wrong pos for next severity check.
    goto_opts.severity = vim.diagnostic.severity[severity]
    if args.get_diag_pos_fn(vim.deepcopy(goto_opts)) then
      -- There is a diagnostic for this severity, jump to it
      args.goto_diag_fn(vim.deepcopy(goto_opts))
      return
    end
    -- otherwise, check the next severity..
    -- vim.notify("no more diag with severity "..severity..", checking next..", vim.log.levels.DEBUG) -- DEBUG
  end
  vim.notify("Zero diagnostics left 👍", vim.log.levels.INFO)
end

my_actions.goto_next_diag = mk_action_v2 {
  default_desc = "Go to next diagnostic (by severity)",
  n = function()
    goto_diag_by_severity_layers {
      get_diag_pos_fn = vim.diagnostic.get_next_pos,
      goto_diag_fn = vim.diagnostic.goto_next,
      goto_opts = {}, -- defaults
    }
  end,
}

my_actions.goto_prev_diag = mk_action_v2 {
  default_desc = "Go to prev diagnostic (by severity)",
  n = function()
    goto_diag_by_severity_layers {
      get_diag_pos_fn = vim.diagnostic.get_prev_pos,
      goto_diag_fn = vim.diagnostic.goto_prev,
      goto_opts = {}, -- defaults
    }
  end,
}

my_actions.goto_next_diag_diff_line = mk_action_v2 {
  default_desc = "Go to next diagnostic (by severity, != line)",
  n = function()
    goto_diag_by_severity_layers {
      get_diag_pos_fn = vim.diagnostic.get_next_pos,
      goto_diag_fn = vim.diagnostic.goto_next,
      goto_opts = {
        -- Start searching from next line
        cursor_position = { --[[ row1 ]] vim.fn.line"." +1, --[[ col0 ]] 0 },
      },
    }
  end,
}

my_actions.goto_prev_diag_diff_line = mk_action_v2 {
  default_desc = "Go to prev diagnostic (by severity, != line)",
  n = function()
    goto_diag_by_severity_layers {
      get_diag_pos_fn = vim.diagnostic.get_prev_pos,
      goto_diag_fn = vim.diagnostic.goto_prev,
      goto_opts = {
        -- Start searching from prev line
        cursor_position = { --[[ row1 ]] vim.fn.line"." -1, --[[ col0 ]] 0 },
      },
    }
  end,
}

my_actions.fuzzy_buf_diags = mk_action_v2 {
  default_desc = "Fuzzy buf diagnostics",
  n = function()
    require"telescope.builtin".diagnostics {
      bufnr = 0,
      layout_strategy = "vertical",
    }
  end,
}
my_actions.fuzzy_all_diags = mk_action_v2 {
  default_desc = "Fuzzy all diagnostics",
  n = function()
    require"telescope.builtin".diagnostics {
      layout_strategy = "vertical",
    }
  end,
}

my_actions.qf_buf_diags = mk_action_v2 {
  default_desc = "Set qf with buf diagnostics",
  n = function()
    vim.diagnostic.setloclist { title = "Buffer Diagnostics" }
  end,
}

my_actions.qf_all_diags = mk_action_v2 {
  default_desc = "Set qf with all diagnostics",
  n = function()
    vim.diagnostic.setqflist { title = "All Diagnostics" }
  end,
}

my_actions.qf_buf_diags_by_severity = mk_action_v2 {
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

my_actions.qf_all_diags_by_severity = mk_action_v2 {
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

local_leader_map_define_group{mode={"n"}, prefix_key="d", name="+diagnostics"}
local_leader_map{mode="n", key="dd", desc="Show diagnostics in popup", action=vim.diagnostic.open_float}
local_leader_map{mode="n", key="dn", action=my_actions.goto_next_diag}
local_leader_map{mode="n", key="dp", action=my_actions.goto_prev_diag}
local_leader_map{mode="n", key="dj", action=my_actions.goto_next_diag_diff_line}
local_leader_map{mode="n", key="dk", action=my_actions.goto_prev_diag_diff_line}
local_leader_map{mode="n", key="df", action=my_actions.fuzzy_buf_diags}
local_leader_map{mode="n", key="dF", action=my_actions.fuzzy_all_diags}
local_leader_map{mode="n", key="dq", action=my_actions.qf_buf_diags_by_severity}
local_leader_map{mode="n", key="dQ", action=my_actions.qf_all_diags_by_severity}
