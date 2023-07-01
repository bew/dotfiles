-- https://github.com/nvim-lua/plenary.nvim#plenarytest_harness

local get_pos_of_indented_bol = require"smart-bol.core".get_pos_of_indented_bol

local eq = assert.are.same

local function text_to_col_and_line(text)
  local cursor_col_i = text:find("|")
  local cursor_col_n = text:find("_")
  local line, cursor_col
  if cursor_col_i then
    -- insert mode cursor, text is around cursor
    cursor_col = cursor_col_i
    line = text:sub(1, cursor_col -1) .. text:sub(cursor_col +1)
  else
    -- normal mode cursor, cursor is on text
    cursor_col = cursor_col_n
    line = text:gsub("_", " ")
  end
  assert(cursor_col, "need a '|' or '_' in text!")
  assert(line, "no line??")
  return cursor_col, line
end

local function check_cursor_movement(opts)
  local text_to_check, expected_text = opts.text, opts.expected

  local cursor_col1, line = text_to_col_and_line(text_to_check)
  local expected_col1 = text_to_col_and_line(expected_text)

  local target_col1 = get_pos_of_indented_bol(line)
  eq(expected_col1, target_col1)
end

describe("smart-bol get_pos_of_indented_bol", function()
  -- BOL: Beginning Of Line (like normal mode '0')
  -- I-BOL: Indented Beginning Of Line (like normal mode '^')

  it("gives I-BOL when only spaces, start at BOL", function()
    check_cursor_movement{text = "_  ", expected = "  _"}
  end)
  it("gives I-BOL when only spaces, start in the middle", function()
    check_cursor_movement{text = "  _  ", expected = "    _"}
  end)

  it("gives I-BOL when only text, start in text", function()
    check_cursor_movement{text = "foo b|ar", expected = "|foo bar"}
    check_cursor_movement{text = "foo bar|", expected = "|foo bar"}
  end)

  it("gives I-BOL when spaces and text, start in text", function()
    check_cursor_movement{text = "  foo b|ar", expected = "  |foo bar"}
    check_cursor_movement{text = "  foo bar|", expected = "  |foo bar"}
  end)

  it("gives I-BOL when spaces and text, start at BOL", function()
    check_cursor_movement{text = "|  foo bar", expected = "  |foo bar"}
  end)

  it("gives I-BOL when at I-BOL", function()
    check_cursor_movement{text = "  |foo bar", expected = "  |foo bar"}
  end)

  it("gives BOL when at BOL or line is empty", function()
    check_cursor_movement{text = "|foo bar", expected = "|foo bar"}
    check_cursor_movement{text = "|", expected = "|"}
  end)
end)
