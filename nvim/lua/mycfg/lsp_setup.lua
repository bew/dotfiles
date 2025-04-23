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
