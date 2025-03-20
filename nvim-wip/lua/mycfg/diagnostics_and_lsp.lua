
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

--- Jump to next/prev diagnostic by layer of severity.
--- Search for ERROR severity, if none search for WARN severity, if none search for HINT severity.
---@param args mycfg.diag.GotoDiagBySevArgs
local goto_diag_by_severity_layers = function(args)
  local goto_opts = args.goto_opts
  for _, severity in ipairs({"ERROR", "WARN", "HINT"}) do
    goto_opts.severity = vim.diagnostic.severity[severity]
    if args.get_diag_pos_fn(goto_opts) then
      -- There is a diagnostic for this severity, jump to it
      args.goto_diag_fn(goto_opts)
      return
    end
    -- otherwise, check the next severity..
    print("no more diag with severity "..severity..", checking next severity..", vim.log.levels.DEBUG)
  end
  vim.notify("Zero diagnostics left 👍", vim.log.levels.INFO)
end

my_actions.goto_next_diag = mk_action_v2 {
  default_desc = "Go to next diagnostic (by severity)",
  n = function()
    goto_diag_by_severity_layers {
      get_diag_pos_fn = vim.diagnostic.get_next_os,
      goto_diag_fn = vim.diagnostic.goto_next,
      goto_opts = {}, -- defaults
    }
  end,
}

my_actions.goto_prev_diag = mk_action_v2 {
  default_desc = "Go to prev diagnostic (by severity)",
  n = function()
    goto_diag_by_severity_layers {
      get_diag_pos_fn = vim.diagnostic.get_prev_os,
      goto_diag_fn = vim.diagnostic.goto_prev,
      goto_opts = {}, -- defaults
    }
  end,
}

my_actions.goto_next_diag_diff_line = mk_action_v2 {
  default_desc = "Go to next diagnostic (by severity, != line)",
  n = function()
    goto_diag_by_severity_layers {
      get_diag_pos_fn = vim.diagnostic.get_next_os,
      goto_diag_fn = vim.diagnostic.goto_next,
      goto_opts = {
        -- Start searching from next line
        cursor_position = { --[[ row1 ]] vim.fn.line('.') + 1, --[[ col0 ]] 0 },
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
        cursor_position = { --[[ row1 ]] vim.fn.line('.') - 1, --[[ col0 ]] 0 },
      },
    }
  end,
}

local_leader_map_define_group{mode={"n"}, prefix_key="d", name="+diagnostics"}
local_leader_map{mode="n", key="dd", desc="Show diagnostics in popup", action=vim.diagnostic.open_float}
local_leader_map{mode="n", key="dn", action=my_actions.goto_next_diag}
local_leader_map{mode="n", key="dp", action=my_actions.goto_prev_diag}
local_leader_map{mode="n", key="dj", action=my_actions.goto_next_diag_diff_line}
local_leader_map{mode="n", key="dk", action=my_actions.goto_prev_diag_diff_line}

vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'LSP actions',
  callback = function(_event)
    -- Trigger LSP completion
    --toplevel_map{mode="i", key="<C-Space>", opts=buf_opts, action="<C-x><C-o>"}

    -- Display documentation of the symbol under the cursor
    toplevel_buf_map{mode="n", key="K", desc="Show docs", action=vim.lsp.buf.hover}
    local_leader_buf_map{mode="n", key="c<LocalLeader>", desc="Show docs", action=vim.lsp.buf.hover}

    local_leader_buf_map{mode="n", key="cd", desc="Jump to def", action=vim.lsp.buf.definition}
    local_leader_buf_map{mode="n", key="cD", desc="Jump to decl", action=vim.lsp.buf.declaration}
    local_leader_buf_map{mode="n", key="ct", desc="Jump to type def", action=vim.lsp.buf.type_definition}

    local_leader_buf_map{mode="n", key="ci", desc="List impls", action=vim.lsp.buf.implementation}
    local_leader_buf_map{mode="n", key="cu", desc="List usages", action=vim.lsp.buf.references}

    -- Displays a function"s signature information
    toplevel_buf_map{mode="i", key="<C-s>", desc="Show signature", action=vim.lsp.buf.signature_help}
    local_leader_buf_map{mode="n", key="cs", desc="Show signature", action=vim.lsp.buf.signature_help}

    -- Renames all references to the symbol under the cursor
    local_leader_buf_map{mode="n", key="cr", desc="Rename", action=vim.lsp.buf.rename}

    -- Format current file
    -- local_leader_buf_map{mode="n", key="<C-M-f>", action=vim.lsp.buf.format}

    -- Selects a code action available at the current cursor position
    local_leader_buf_map{mode="n", key="a", desc="Code actions", action=vim.lsp.buf.code_action} -- 🤔
    local_leader_buf_map{mode="n", key="ca", desc="Code actions", action=vim.lsp.buf.code_action}
  end
})
