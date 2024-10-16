
local function start_lsp_server()
  local pylsp_settings = { pylsp = { plugins = {} } }
  -- When pylsp-mypy is installed
  pylsp_settings.pylsp.plugins.pylsp_mypy = {
    live_mode = false, -- update mypy diags on save (not live)
    dmypy = true,
    report_progress = true,
    overrides = {
      true, -- special value to add plugin's default params for mypy
      "--check-untyped-defs", -- ensure all functions are checked!
      "--disallow-incomplete-defs"
    },
  }
  -- WHen python-lsp-ruff is installed
  pylsp_settings.pylsp.plugins.ruff = {
    enabled = true,
    extendSelect = {"RUF"}, -- Ensure these rules are always checked
    unsafeFixes = true, -- Offer unsafe fixes as code actions (Ignored for `Fix All`)

    -- Following settings are ignored if a pyproject.toml exists
    lineLength = 100,
    -- ref: https://docs.astral.sh/ruff/rules/
    select = {"F", "E", "W", "N", "UP", "RUF"},
  }

  vim.lsp.start {
    -- https://github.com/python-lsp/python-lsp-server
    name = "pylsp",
    cmd = {"pylsp"},
    -- TODO: Move this in a central location in config (it's not specific to Rust!)
    capabilities = vim.tbl_deep_extend(
      "force",
      vim.lsp.protocol.make_client_capabilities(),
      require"cmp_nvim_lsp".default_capabilities(),
      {
        -- Disable snippets in completion candidates
        textDocument = { completion = { completionItem = { snippetSupport = false } } }
      }
    ),
    settings = pylsp_settings,
    single_file_support = true,

    root_dir = vim.fs.root(0, {
      "pyproject.toml",
      "setup.py",
      "setup.cfg",
      "requirements.txt",
    }),
  }
end
if vim.fn.executable("pylsp") == 1 then
  start_lsp_server()
else
  vim.notify("LSP not found")
end
