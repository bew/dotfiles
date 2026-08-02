-- Auto-fold translated option groups in .desktop files.
-- Lines like `Name[fr]=...`, `Name[de]=...` are folded per base key.

-- Matches a translated option key: letter-started key name before `[` (e.g. `Name` in `Name[fr]=...`)
local TRANSLATED_KEY_RX = "^(%a[%a%d_-]*)%["

local function desktop_foldexpr(lnum)
  local line = vim.fn.getline(lnum)

  -- Is this line a translated option? (e.g. `Name[fr]=...`) → capture key name before `[`
  local base_key = line:match(TRANSLATED_KEY_RX)
  if not base_key then
    return "0"
  end

  -- Check previous line: same pattern, capture key name before `[`
  local prev = vim.fn.getline(lnum - 1)
  local prev_key = prev:match(TRANSLATED_KEY_RX)

  if prev_key ~= base_key then
    -- First translated line of this key group → start fold
    return ">1"
  else
    -- Continuation of same key group
    return "1"
  end
end

local function desktop_foldtext()
  local start_lnum = vim.v.foldstart
  local end_lnum = vim.v.foldend
  local count = end_lnum - start_lnum + 1

  local first_line = vim.fn.getline(start_lnum)
  -- Capture key name before `[` (same as in foldexpr)
  local base_key = first_line:match(TRANSLATED_KEY_RX)

  -- Try preferred locales in order, skip example if none found
  local preferred = { "en", "fr", "en_GB" }
  local example_value = nil
  local example_locale = nil
  for _, locale in ipairs(preferred) do
    for lnum = start_lnum, end_lnum do
      local line = vim.fn.getline(lnum)
      -- Capture locale between `[` and `]`, then value after `=`
      local lang, value = line:match("^[^%[]*%[([^%]]+)%]=(.*)$")
      if lang == locale then
        example_value = value
        example_locale = lang
        goto found_example
      end
    end
  end
  ::found_example::

  local example_part = ""
  if example_value and example_locale then
    example_part = string.format(" | Example[%s]: %s", example_locale, example_value)
  end
  return string.format("%s[...] (%d translations)%s", base_key, count, example_part)
end

_G._desktop_foldexpr = desktop_foldexpr
_G._desktop_foldtext  = desktop_foldtext

vim.opt_local.foldmethod = "expr"
vim.opt_local.foldexpr = "v:lua._desktop_foldexpr(v:lnum)"
vim.opt_local.foldtext = "v:lua._desktop_foldtext()"

-- Close all folds after the buffer is fully loaded
vim.api.nvim_create_autocmd("BufWinEnter", {
  buffer = vim.api.nvim_get_current_buf(),
  once = true,
  callback = function() vim.cmd("normal! zM") end,
})
