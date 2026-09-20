-- nvimq_backend.lua
-- Stateless fact service for `nvimq`: runs inside `nvim -l`, reads one JSON
-- request per stdin line, writes one JSON response per line to stdout.
-- Resolves help doc dirs and reports vimdoc parse facts; all selection and
-- rendering live in the `nvimq` Python CLI.

local CORE = "core"
local PLUGIN = "plugin"
local CODEBLOCK = "codeblock"
local CLOSE_MARKER = "<"
local HEADING_LEVELS = { h1 = 1, h2 = 2, h3 = 3, column_heading = 4 }

-- ------------------------------------------------------------------------------
-- Protocol

--- Abort the current request with a user-facing message.
---
--- Uses level 0 so the message reaches the caller unprefixed; the request loop
--- turns it into an `{ error = ... }` response.
---@param msg string
local function fail(msg)
  error(msg, 0)
end

--- Write one JSON response line to stdout and flush.
---@param response table
local function respond(response)
  io.write(vim.json.encode(response), "\n")
  io.stdout:flush()
end

-- ------------------------------------------------------------------------------
-- Doc-dir resolution

--- Return the OS path-list separator used by `NVIMQ_DOC_ROOT`.
---@return string
local function path_list_separator()
  if vim.fn.has("win32") == 1 then
    return ";"
  end
  return ":"
end

--- Classify a doc dir as `core` (bundled runtime) or `plugin`.
---
--- Core means the path lies under `$VIMRUNTIME/doc`, or has an adjacent
--- `runtime/doc` component pair.
---@param path string
---@return string
local function classify_scope(path)
  local absolute = vim.fn.fnamemodify(path, ":p")
  local runtime = vim.env.VIMRUNTIME
  if runtime and runtime ~= "" then
    local runtime_doc = vim.fn.fnamemodify(runtime .. "/doc", ":p")
    if absolute:sub(1, #runtime_doc) == runtime_doc then
      return CORE
    end
  end
  if absolute:find("/runtime/doc/", 1, true) then
    return CORE
  end
  return PLUGIN
end

--- Resolve the help doc dirs, in runtimepath order.
---
--- With `NVIMQ_DOC_ROOT` set (path-list separated) the listed dirs are used
--- verbatim, which keeps tests hermetic. Otherwise `$VIMRUNTIME/doc` plus every
--- `doc/tags` on the runtimepath is used.
---@return table[] dirs each `{ path, scope }`
local function resolve_doc_dirs()
  local dirs = {}
  local seen = {}

  --- Append a doc dir once, ignoring duplicates and empty entries.
  ---@param path string|nil
  local function add(path)
    if not path or path == "" then
      return
    end
    local absolute = vim.fn.fnamemodify(path, ":p"):gsub("/+$", "")
    if absolute == "" or seen[absolute] then
      return
    end
    seen[absolute] = true
    dirs[#dirs + 1] = { path = absolute, scope = classify_scope(absolute) }
  end

  local override = vim.env.NVIMQ_DOC_ROOT
  if override and override ~= "" then
    local entries = vim.split(override, path_list_separator(), { plain = true })
    for _, entry in ipairs(entries) do
      local trimmed = vim.trim(entry)
      if trimmed ~= "" then
        if vim.fn.isdirectory(trimmed) ~= 1 then
          fail("NVIMQ_DOC_ROOT entry is not a directory: " .. trimmed)
        end
        add(trimmed)
      end
    end
    if #dirs == 0 then
      fail("NVIMQ_DOC_ROOT is set but lists no directories")
    end
    return dirs
  end

  if vim.env.VIMRUNTIME and vim.env.VIMRUNTIME ~= "" then
    add(vim.env.VIMRUNTIME .. "/doc")
  end
  for _, tags_path in ipairs(vim.api.nvim_get_runtime_file("doc/tags", true)) do
    add(vim.fn.fnamemodify(tags_path, ":h"))
  end
  if #dirs == 0 then
    fail("could not resolve nvim runtime doc paths; is nvim installed?")
  end
  return dirs
end

---@param req table
---@return table
local function handle_doc_dirs(req)
  return { dirs = resolve_doc_dirs() }
end

-- ------------------------------------------------------------------------------
-- Help-file parsing

--- Read a help file, or return an empty list when it cannot be read.
---@param path string
---@return string[]
local function read_lines(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or type(lines) ~= "table" then
    return {}
  end
  return lines
end

--- Parse help-file lines with the bundled `vimdoc` parser.
---@param lines string[]
---@return string text
---@return TSNode root
local function parse_lines(lines)
  local text = table.concat(lines, "\n")
  local ok, parser = pcall(vim.treesitter.get_string_parser, text, "vimdoc")
  if not ok then
    fail("vimdoc parser unavailable: " .. tostring(parser))
  end
  local tree = parser:parse()[1]
  return text, tree:root()
end

--- Collect all headings from a parsed help file, in document order.
---
--- `start_row` is the ruler row for h1/h2 and the heading row otherwise;
--- `heading_row` is where the title lives.
---@param root TSNode
---@param text string
---@return table[] headings
local function collect_headings(root, text)
  local headings = {}

  ---@param node TSNode
  local function walk(node)
    local level = HEADING_LEVELS[node:type()]
    if level then
      local start_row = node:range()
      local heading_node
      local tags = {}
      for child in node:iter_children() do
        local child_type = child:type()
        if child_type == "heading" then
          heading_node = child
        elseif child_type == "tag" then
          local tag_text = vim.treesitter.get_node_text(child, text)
          tags[#tags + 1] = tag_text:gsub("^%*", ""):gsub("%*$", "")
        end
      end
      local heading_row = start_row
      if level == 1 or level == 2 then
        heading_row = start_row + 1
      end
      headings[#headings + 1] = {
        level = level,
        title = heading_node
            and vim.trim(vim.treesitter.get_node_text(heading_node, text))
          or "",
        tags = tags,
        start_row = start_row,
        heading_row = heading_row,
      }
    end
    for child in node:iter_children() do
      walk(child)
    end
  end

  walk(root)
  table.sort(headings, function(a, b)
    return a.start_row < b.start_row
  end)
  return headings
end

--- Collect code blocks and `<` close-marker rows from the parse tree.
---@param root TSNode
---@param text string
---@return table[] blocks each `{ opener_row, opener_col, code_start, code_end, lang }`
---@return table<integer, boolean> close_rows
local function collect_code_blocks(root, text)
  local blocks = {}
  local close_rows = {}

  ---@param node TSNode
  local function walk(node)
    local node_type = node:type()
    if node_type == CODEBLOCK then
      local opener_row, opener_col = node:range()
      local code_start, code_end
      local lang = ""
      for child in node:iter_children() do
        local child_type = child:type()
        if child_type == "code" then
          local start_row, _, end_row = child:range()
          code_start, code_end = start_row, end_row
        elseif child_type == "language" then
          lang = vim.trim(vim.treesitter.get_node_text(child, text))
        end
      end
      blocks[#blocks + 1] = {
        opener_row = opener_row,
        opener_col = opener_col,
        code_start = code_start,
        code_end = code_end,
        lang = lang,
      }
    elseif node_type == CLOSE_MARKER then
      close_rows[node:range()] = true
    end
    for child in node:iter_children() do
      walk(child)
    end
  end

  walk(root)
  return blocks, close_rows
end

--- Partition a help file into ordered AST blocks with minimal normalization.
---
--- Every source row belongs to exactly one block: a heading owns its ruler and
--- title rows, a code block owns its opener, code, and close-marker rows, and a
--- text block owns the rest. Python renders those facts into markdown.
---@param lines string[]
---@param root TSNode
---@param text string
---@param headings table[]
---@return table[] blocks
local function build_blocks(lines, root, text, headings)
  local heading_by_start = {}
  for _, heading in ipairs(headings) do
    heading_by_start[heading.start_row] = heading
  end
  local code_blocks, close_rows = collect_code_blocks(root, text)
  local code_by_opener = {}
  for _, block in ipairs(code_blocks) do
    code_by_opener[block.opener_row] = block
  end

  local blocks = {}
  local text_start
  local text_lines = {}

  --- Emit the pending run of unowned rows as one text block.
  local function flush_text()
    if text_start then
      blocks[#blocks + 1] = {
        type = "text",
        start_row = text_start,
        lines = text_lines,
      }
      text_start = nil
      text_lines = {}
    end
  end

  --- Emit a heading block and return the first row after it.
  ---@param heading table
  ---@return integer
  local function push_heading(heading)
    blocks[#blocks + 1] = {
      type = "heading",
      level = heading.level,
      start_row = heading.start_row,
      heading_row = heading.heading_row,
      line = lines[heading.heading_row + 1] or "",
      title = heading.title,
      tags = heading.tags,
    }
    return heading.heading_row + 1
  end

  --- Emit a code block and return the first row after it.
  ---@param block table
  ---@return integer
  local function push_code(block)
    local code_lines = {}
    if block.code_start and block.code_end then
      for row = block.code_start, block.code_end - 1 do
        code_lines[#code_lines + 1] = lines[row + 1] or ""
      end
    end
    local close_row
    if block.code_end and close_rows[block.code_end] then
      close_row = block.code_end
    end
    local end_row = close_row
      or (block.code_end and block.code_end - 1 or block.opener_row)
    blocks[#blocks + 1] = {
      type = "code",
      opener_row = block.opener_row,
      opener_col = block.opener_col,
      opener_line = lines[block.opener_row + 1] or "",
      code_start = block.code_start or block.opener_row,
      lang = block.lang,
      lines = code_lines,
    }
    return end_row + 1
  end

  local row = 0
  local line_count = #lines
  while row < line_count do
    local heading = heading_by_start[row]
    local code = code_by_opener[row]
    if heading then
      flush_text()
      row = push_heading(heading)
    elseif code then
      flush_text()
      row = push_code(code)
    else
      if not text_start then
        text_start = row
      end
      text_lines[#text_lines + 1] = lines[row + 1] or ""
      row = row + 1
    end
  end
  flush_text()
  return blocks
end

---@param req table
---@return table
local function handle_read(req)
  return { lines = read_lines(req.path) }
end

---@param req table
---@return table
local function handle_headings(req)
  local lines = read_lines(req.path)
  local text, root = parse_lines(lines)
  return { line_count = #lines, headings = collect_headings(root, text) }
end

---@param req table
---@return table
local function handle_parse(req)
  local lines = read_lines(req.path)
  local text, root = parse_lines(lines)
  local headings = collect_headings(root, text)
  return {
    line_count = #lines,
    headings = headings,
    blocks = build_blocks(lines, root, text, headings),
  }
end

-- ------------------------------------------------------------------------------
-- Regex matching

--- Return the subset of `req.names` matching `req.pattern` as a Vim regex.
---
--- An invalid pattern yields no matches so the caller's substring/glob checks
--- still apply.
---@param req table
---@return table
local function handle_match(req)
  local ok, regex = pcall(vim.regex, "\\c\\v" .. req.pattern)
  if not ok then
    return { matches = {} }
  end
  local matches = {}
  for _, name in ipairs(req.names or {}) do
    if regex:match_str(name) then
      matches[#matches + 1] = name
    end
  end
  return { matches = matches }
end

-- ------------------------------------------------------------------------------
-- Request loop

local HANDLERS = {
  doc_dirs = handle_doc_dirs,
  read = handle_read,
  headings = handle_headings,
  parse = handle_parse,
  match = handle_match,
}

--- Decode one request line and dispatch it to the matching handler.
---@param raw string
---@return table
local function dispatch(raw)
  local ok, req = pcall(vim.json.decode, raw)
  if not ok or type(req) ~= "table" then
    fail("invalid JSON request: " .. raw)
  end
  local handler = HANDLERS[req.kind]
  if not handler then
    fail("unknown request kind: " .. tostring(req.kind))
  end
  return handler(req)
end

local function main()
  while true do
    local raw = io.read("*l")
    if not raw then
      break
    end
    -- A handler error becomes an error response; the loop keeps serving.
    local ok, response = pcall(dispatch, raw)
    if ok then
      respond(response)
    else
      respond({ error = tostring(response) })
    end
  end
end

main()