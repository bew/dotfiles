local U = require"mylib.utils"
local _f = U.fmt.str_space_concat


vim.api.nvim_create_user_command("TrimWhitespaces", function(opts)
  ---@cast opts vim.api.keyset.create_user_command.command_args

  local start_line0 = opts.line1 - 1  -- nvim_buf_get_lines is 0-indexed
  local end_line0   = opts.line2      -- exclusive end
  local lines = vim.api.nvim_buf_get_lines(0, start_line0, end_line0, false)

  local modified_lines = 0
  for line_idx, line in ipairs(lines) do
    local trimmed = line:gsub("%s+$", "")
    if trimmed ~= line then
      local buf_line0 = start_line0 + line_idx - 1
      -- Remove only the trailing whitespace span (chirurgical!)
      vim.api.nvim_buf_set_text(0, buf_line0, #trimmed, buf_line0, #line, {})
      modified_lines = modified_lines + 1
    end
  end

  if modified_lines ~= 0 then
    vim.notify(_f("Trimmed", modified_lines, "lines!"), vim.log.levels.INFO)
  else
    vim.notify("No lines to trim!", vim.log.levels.INFO)
  end
end, {
  desc = "Trim whitespaces",
  range = "%", -- Default to the whole file
})
