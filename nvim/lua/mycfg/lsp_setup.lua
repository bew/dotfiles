local K = require"mylib.keymap_system"

K.local_leader_map_define_group{mode="n", prefix_key="c", name="+code/content"}
vim.api.nvim_create_autocmd("LspAttach", {
  desc = "LSP actions",
  callback = function(_event)
    -- Trigger LSP completion
    --toplevel_map{mode="i", key="<C-Space>", opts=buf_opts, action="<C-x><C-o>"}

    -- Display documentation of the symbol under the cursor
    K.toplevel_buf_map{mode="n", key="K", desc="Show docs", action=vim.lsp.buf.hover}
    K.local_leader_buf_map{mode="n", key="c<LocalLeader>", desc="Show docs", action=vim.lsp.buf.hover}

    K.local_leader_buf_map{mode="n", key="cd", desc="Jump to def", action=vim.lsp.buf.definition}
    K.local_leader_buf_map{mode="n", key="cD", desc="Jump to decl", action=vim.lsp.buf.declaration}
    K.local_leader_buf_map{mode="n", key="ct", desc="Jump to type def", action=vim.lsp.buf.type_definition}

    K.local_leader_buf_map{mode="n", key="ci", desc="List impls", action=vim.lsp.buf.implementation}
    K.local_leader_buf_map{mode="n", key="cu", desc="List usages", action=vim.lsp.buf.references}

    -- Displays a function"s signature information
    K.toplevel_buf_map{mode="i", key="<C-s>", desc="Show signature", action=vim.lsp.buf.signature_help}
    K.local_leader_buf_map{mode="n", key="cs", desc="Show signature", action=vim.lsp.buf.signature_help}

    -- Renames all references to the symbol under the cursor
    K.local_leader_buf_map{mode="n", key="cr", desc="Rename", action=vim.lsp.buf.rename}

    -- Format current file
    -- local_leader_buf_map{mode="n", key="<C-M-f>", action=vim.lsp.buf.format}

    -- Selects a code action available at the current cursor position
    K.local_leader_buf_map{mode="n", key="a", desc="Code actions", action=vim.lsp.buf.code_action} -- 🤔
    K.local_leader_buf_map{mode="n", key="ca", desc="Code actions", action=vim.lsp.buf.code_action}
  end
})
