-- nvimq_backend.lua
-- Lua backend for `nvimq`: runs inside `nvim -l`, resolves help doc dirs, parses
-- help files with the bundled `vimdoc` treesitter parser, and renders results.
-- Not meant to be run directly; invoked by the `nvimq` Python CLI.

local CORE = "core"
local PLUGIN = "plugin"

local DEFAULT_TAG_WINDOW = 40
local CODEBLOCK = "codeblock"
local CLOSE_MARKER = "<"

local HEADING_LEVELS = { h1 = 1, h2 = 2, h3 = 3, column_heading = 4 }

-- ------------------------------------------------------------------------------
-- Diagnostics

--- Print an error to stderr and exit with status 1.
---@param msg string
local function fail(msg)
  io.stderr:write("!! ERROR: " .. msg .. "\n")
  io.stderr:flush()
  os.exit(1)
end

--- Print a warning line to stderr.
---@param msg string
local function warn(msg)
  io.stderr:write(msg .. "\n")
  io.stderr:flush()
end

--- Write rendered lines to stdout, one per line.
---@param lines string[]
local function emit(lines)
  if #lines == 0 then
    return
  end
  io.write(table.concat(lines, "\n"), "\n")
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
--- Core means the path has an adjacent `runtime/doc` component pair, or lies
--- under `$VIMRUNTIME/doc`.
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

-- ------------------------------------------------------------------------------
-- Index building

--- Map lowercased help stems to files, first doc dir (runtimepath) winning.
---@param dirs table[]
---@return table<string, table> docs keyed by lowercased stem
---@return table[] order docs in runtimepath order
local function build_file_index(dirs)
  local docs = {}
  local order = {}
  for _, dir in ipairs(dirs) do
    local names = vim.fn.readdir(dir.path)
    table.sort(names)
    for _, name in ipairs(names) do
      if name:lower():sub(-4) == ".txt" then
        local stem = name:sub(1, -5)
        local key = stem:lower()
        if not docs[key] then
          local doc = { stem = stem, path = dir.path .. "/" .. name, scope = dir.scope }
          docs[key] = doc
          order[#order + 1] = doc
        end
      end
    end
  end
  return docs, order
end

--- Parse every `tags` file, keeping entries whose help file is indexed.
---@param dirs table[]
---@param docs table<string, table>
---@return table[] tags each `{ name, doc }`
---@return table<string, table[]> tags_by_doc keyed by doc path
local function build_tag_index(dirs, docs)
  local tags = {}
  local tags_by_doc = {}
  for _, dir in ipairs(dirs) do
    local tags_path = dir.path .. "/tags"
    if vim.fn.filereadable(tags_path) == 1 then
      for _, raw in ipairs(vim.fn.readfile(tags_path)) do
        local parts = vim.split(raw, "\t", { plain = true })
        if #parts >= 3 then
          local name = parts[1]
          local filename = parts[2]
          if filename:lower():sub(-4) == ".txt" then
            local doc = docs[filename:sub(1, -5):lower()]
            if doc then
              local entry = { name = name, doc = doc }
              tags[#tags + 1] = entry
              tags_by_doc[doc.path] = tags_by_doc[doc.path] or {}
              table.insert(tags_by_doc[doc.path], entry)
            end
          end
        end
      end
    end
  end
  return tags, tags_by_doc
end

--- Build the full help index for the resolved doc dirs.
---@return table index with `docs`, `order`, `tags`, `tags_by_doc`
local function build_index()
  local dirs = resolve_doc_dirs()
  local docs, order = build_file_index(dirs)
  local tags, tags_by_doc = build_tag_index(dirs, docs)
  return { docs = docs, order = order, tags = tags, tags_by_doc = tags_by_doc }
end

-- ------------------------------------------------------------------------------
-- Help-file parsing

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

--- Read a help file and parse it with the bundled `vimdoc` parser.
---@param path string
---@return string[] lines
---@return string text
---@return TSNode root
local function parse_file(path)
  local lines = vim.fn.readfile(path)
  local text, root = parse_lines(lines)
  return lines, text, root
end

--- Collect all headings from a parsed help file, in document order.
---
--- `start_row` is the ruler row for h1/h2 and the heading row otherwise;
--- `heading_row` is where the title lives. `end_row` is filled by
--- `compute_end_rows`.
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

--- Fill each heading's `end_row`: the row before the next heading of equal or
--- higher level, or the last file row.
---@param headings table[]
---@param line_count integer
local function compute_end_rows(headings, line_count)
  for i, heading in ipairs(headings) do
    local end_row = line_count - 1
    for j = i + 1, #headings do
      if headings[j].level <= heading.level then
        end_row = headings[j].start_row - 1
        break
      end
    end
    heading.end_row = end_row
  end
end

--- Return the 0-based row holding the `*name*` anchor, or nil.
---@param lines string[]
---@param name string
---@return integer|nil
local function find_tag_row(lines, name)
  local needle = "*" .. name .. "*"
  for index, line in ipairs(lines) do
    if line:find(needle, 1, true) then
      return index - 1
    end
  end
  return nil
end

-- ------------------------------------------------------------------------------
-- Markdown rendering

--- Strip leading whitespace from a line.
---@param line string
---@return string
local function strip_leading(line)
  return (line:gsub("^%s+", ""))
end

--- Return the smallest leading-whitespace width across non-blank lines.
---@param code_lines string[]
---@return integer
local function common_indent(code_lines)
  local minimum = nil
  for _, line in ipairs(code_lines) do
    if line:match("%S") then
      local indent = #(line:match("^[ \t]*"))
      if minimum == nil or indent < minimum then
        minimum = indent
      end
    end
  end
  return minimum or 0
end

--- Remove up to `count` leading whitespace characters from a line.
---@param line string
---@param count integer
---@return string
local function deindent(line, count)
  local removed = 0
  local index = 1
  while removed < count and index <= #line do
    local char = line:sub(index, index)
    if char == " " or char == "\t" then
      removed = removed + 1
      index = index + 1
    else
      break
    end
  end
  return line:sub(index)
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

--- Build a row-to-output plan for markdown rendering a help file.
---
--- Headings become `#`-prefixed lines; h1/h2 rulers and `~` delimiters are
--- dropped; code blocks become fenced blocks with de-indented code. The closing
--- fence is always emitted after the last code row; an explicit `<` close marker
--- (a separate node) is dropped, and implicit blocks end at the next prose row.
---@param lines string[]
---@param text string
---@param root TSNode
---@param headings table[]
---@return table plan with `drop`, `replace`, `code_line`, `after`
local function build_render_plan(lines, text, root, headings)
  local plan = { drop = {}, replace = {}, code_line = {}, after = {} }

  for _, heading in ipairs(headings) do
    local raw = strip_leading(lines[heading.heading_row + 1] or "")
    if heading.level == 1 then
      plan.drop[heading.start_row] = true
      plan.replace[heading.heading_row] = { "## " .. raw }
    elseif heading.level == 2 then
      plan.drop[heading.start_row] = true
      plan.replace[heading.heading_row] = { "### " .. raw }
    elseif heading.level == 3 then
      plan.replace[heading.heading_row] = { "#### " .. raw }
    else
      plan.replace[heading.heading_row] = { "#### " .. raw:gsub("%s*~%s*$", "") }
    end
  end

  local blocks, close_rows = collect_code_blocks(root, text)
  for _, block in ipairs(blocks) do
    local opener_raw = lines[block.opener_row + 1] or ""
    -- Bytes before the `>` opener are prose that shares the opener row.
    local prose = opener_raw:sub(1, block.opener_col):gsub("%s+$", "")
    local opener_out = {}
    if prose ~= "" then
      opener_out[#opener_out + 1] = prose
    end
    opener_out[#opener_out + 1] = "```" .. block.lang
    plan.replace[block.opener_row] = opener_out

    local close_after = block.opener_row
    if block.code_start and block.code_end then
      local code_lines = {}
      for row = block.code_start, block.code_end - 1 do
        code_lines[#code_lines + 1] = lines[row + 1] or ""
      end
      local indent = common_indent(code_lines)
      for i, line in ipairs(code_lines) do
        plan.code_line[block.code_start + i - 1] = deindent(line, indent)
      end
      close_after = math.max(block.opener_row, block.code_end - 1)
    end
    plan.after[close_after] = { "```" }
    if close_rows[block.code_end] then
      plan.drop[block.code_end] = true
    end
  end

  return plan
end

--- Render raw rows `from_row..to_row` (0-based, inclusive) via the plan.
---@param lines string[]
---@param plan table
---@param from_row integer
---@param to_row integer
---@return string[]
local function render_rows(lines, plan, from_row, to_row)
  local out = {}
  for row = from_row, to_row do
    if plan.replace[row] then
      for _, line in ipairs(plan.replace[row]) do
        out[#out + 1] = line
      end
    elseif not plan.drop[row] then
      out[#out + 1] = plan.code_line[row] or lines[row + 1] or ""
    end
    if plan.after[row] then
      for _, line in ipairs(plan.after[row]) do
        out[#out + 1] = line
      end
    end
  end
  return out
end

--- Return items[first..last] (1-based, inclusive), skipping out-of-range ones.
---@param items string[]
---@param first integer
---@param last integer
---@return string[]
local function slice(items, first, last)
  local out = {}
  for index = first, last do
    if items[index] then
      out[#out + 1] = items[index]
    end
  end
  return out
end

-- ------------------------------------------------------------------------------
-- Selection helpers

--- Resolve a bare stem or `<stem>.txt` to a help file within scope.
---@param index table
---@param file_arg string
---@param scope string
---@return table doc
local function lookup_doc(index, file_arg, scope)
  local stem = file_arg
  if stem:lower():sub(-4) == ".txt" then
    stem = stem:sub(1, -5)
  end
  local doc = index.docs[stem:lower()]
  if not doc then
    fail("help file not found: " .. file_arg)
  end
  if scope ~= "all" and doc.scope ~= scope then
    fail("help file not found: " .. file_arg .. " in scope '" .. scope .. "'")
  end
  return doc
end

--- Strip surrounding `|...|` or `*...*` help markers from a name.
---
--- A `*tag*` is a definition anchor and a `|tag|` is a reference to it; both
--- name the same tag, so callers compare against the stripped inner text. Only
--- a fully wrapped argument is stripped, so a bare regex/glob is left intact.
---@param raw string
---@return string
local function strip_markers(raw)
  local trimmed = vim.trim(raw)
  local inner = trimmed:match("^|(.*)|$") or trimmed:match("^%*(.*)%*$")
  if inner and inner ~= "" then
    return vim.trim(inner)
  end
  return trimmed
end

--- Resolve a name to a heading: ordinal, exact title, tag, or title substring.
---@param headings table[]
---@param name string
---@return table heading
local function resolve_section(headings, name)
  local key = strip_markers(name):lower()
  if key:match("^%d+$") then
    local ordinal = tonumber(key)
    if ordinal >= 1 and ordinal <= #headings then
      return headings[ordinal]
    end
    fail("section number " .. ordinal .. " out of range (1-" .. #headings .. ")")
  end
  for _, heading in ipairs(headings) do
    if heading.title:lower() == key then
      return heading
    end
  end
  for _, heading in ipairs(headings) do
    for _, tag in ipairs(heading.tags) do
      if tag:lower() == key then
        return heading
      end
    end
  end
  for _, heading in ipairs(headings) do
    if heading.title:lower():find(key, 1, true) then
      return heading
    end
  end
  fail("no section matching '" .. name .. "'")
end

--- Return lookup keys for a tag, most specific form first.
---
--- Keys, in order: the marker-stripped query; its `()` variant (both ways,
--- since Lua-function tags are indexed as `name()`); then the query quoted as
--- `'name'`, since option tags are indexed with quotes (`'number'`).
---@param query string
---@return string[]
local function build_tag_keys(query)
  local base = strip_markers(query)
  local keys = {}

  ---@param key string
  local function push(key)
    if key ~= "" then
      keys[#keys + 1] = key:lower()
    end
  end

  push(base)
  if base:sub(-2) == "()" then
    push(base:sub(1, -3))
  else
    push(base .. "()")
  end
  local quoted = base:sub(1, 1) == "'" and base:sub(-1) == "'"
  if not quoted then
    push("'" .. base .. "'")
  end
  return keys
end

--- Convert a glob to an anchored Lua pattern.
---@param glob string
---@return string
local function glob_to_lua(glob)
  local escaped = glob:gsub("([%^%$%(%)%%%.%[%]%+%-])", "%%%1")
  escaped = escaped:gsub("%*", ".*"):gsub("%?", ".")
  return "^" .. escaped .. "$"
end

--- Build a predicate matching names by substring, glob, or Vim regex.
---@param pattern string
---@return fun(name: string): boolean
local function build_matcher(pattern)
  local lowered = pattern:lower()
  local glob = glob_to_lua(lowered)
  local regex_ok, regex = pcall(vim.regex, "\\c\\v" .. pattern)
  return function(name)
    local lowered_name = name:lower()
    if lowered_name:find(lowered, 1, true) then
      return true
    end
    if lowered_name:find(glob) then
      return true
    end
    if regex_ok and regex:match_str(name) then
      return true
    end
    return false
  end
end

-- ------------------------------------------------------------------------------
-- Subcommand handlers

--- Print the rendered block around the first in-scope matching tag.
---@param req table
---@param index table
local function cmd_tag(req, index)
  local query = req.tag
  local matches = {}
  for _, key in ipairs(build_tag_keys(query)) do
    for _, entry in ipairs(index.tags) do
      if entry.name:lower() == key then
        matches[#matches + 1] = entry
      end
    end
    if #matches > 0 then
      break
    end
  end

  local scoped = {}
  for _, entry in ipairs(matches) do
    if req.scope == "all" or entry.doc.scope == req.scope then
      scoped[#scoped + 1] = entry
    end
  end
  if #scoped == 0 then
    if #matches > 0 then
      fail("tag '" .. query .. "' exists only outside scope '" .. req.scope .. "'")
    end
    fail("unknown tag: " .. query)
  end

  -- Collapse entries that resolve to the same anchor row (e.g. `LSP` and `lsp`
  -- share a line), so only genuinely distinct definitions trigger a warning.
  local lines_cache = {}
  local seen = {}
  local unique = {}
  for _, entry in ipairs(scoped) do
    local lines = lines_cache[entry.doc.path]
    if not lines then
      lines = vim.fn.readfile(entry.doc.path)
      lines_cache[entry.doc.path] = lines
    end
    local row = find_tag_row(lines, entry.name)
    local key = entry.doc.path .. "\0" .. (row or ("nil:" .. entry.name:lower()))
    if not seen[key] then
      seen[key] = true
      unique[#unique + 1] = { entry = entry, lines = lines, row = row }
    end
  end
  if #unique > 1 then
    warn("!! WARNING: tag '" .. query .. "' is ambiguous (" .. #unique .. " matches):")
    for _, match in ipairs(unique) do
      warn("   " .. match.entry.doc.stem .. ".txt (" .. match.entry.doc.scope .. ")")
    end
  end

  local chosen = unique[1]
  local entry = chosen.entry
  if not chosen.row then
    fail(
      "tag '"
        .. entry.name
        .. "' indexed in "
        .. entry.doc.stem
        .. ".txt but its anchor was not found"
    )
  end
  local lines = chosen.lines
  local anchor = chosen.row
  local text, root = parse_lines(lines)
  local headings = collect_headings(root, text)
  local plan = build_render_plan(lines, text, root, headings)

  local window = DEFAULT_TAG_WINDOW
  local rendered
  if req.lines then
    local last_wanted = req.lines[2]
    while true do
      local to_row = math.min(#lines - 1, anchor + window - 1)
      rendered = render_rows(lines, plan, anchor, to_row)
      if #rendered >= last_wanted or to_row >= #lines - 1 then
        break
      end
      window = window + DEFAULT_TAG_WINDOW
    end
    rendered = slice(rendered, req.lines[1], req.lines[2])
  else
    local to_row = math.min(#lines - 1, anchor + window - 1)
    rendered = render_rows(lines, plan, anchor, to_row)
  end
  emit(rendered)
end

--- List a help file's headings with source-line counts.
---@param req table
---@param index table
local function cmd_toc(req, index)
  if req.max_depth and req.max_depth < 1 then
    fail("-L must be a positive integer")
  end
  local doc = lookup_doc(index, req.file, req.scope)
  local lines, text, root = parse_file(doc.path)
  local headings = collect_headings(root, text)
  compute_end_rows(headings, #lines)

  local out = { doc.stem .. ".txt" }
  for _, heading in ipairs(headings) do
    if not req.max_depth or heading.level <= req.max_depth then
      local indent = string.rep("  ", heading.level - 1)
      local count = heading.end_row - heading.start_row + 1
      out[#out + 1] = indent .. heading.title .. "  (" .. count .. " lines)"
    end
  end
  emit(out)
end

--- Print whole file or selected sections, sliced by rendered line range.
---@param req table
---@param index table
local function cmd_section(req, index)
  local file_part, inline_name = req.target:match("^([^:]*):(.*)$")
  if not file_part then
    file_part = req.target
  end
  local names = {}
  if inline_name and inline_name ~= "" then
    names[#names + 1] = inline_name
  end
  for _, name in ipairs(req.names or {}) do
    names[#names + 1] = name
  end

  local doc = lookup_doc(index, file_part, req.scope)
  local lines, text, root = parse_file(doc.path)
  local headings = collect_headings(root, text)
  compute_end_rows(headings, #lines)
  local plan = build_render_plan(lines, text, root, headings)

  local rendered = {}
  if #names == 0 then
    rendered = render_rows(lines, plan, 0, #lines - 1)
  else
    for position, name in ipairs(names) do
      local heading = resolve_section(headings, name)
      if position > 1 then
        rendered[#rendered + 1] = ""
      end
      local section_lines =
        render_rows(lines, plan, heading.start_row, heading.end_row)
      for _, line in ipairs(section_lines) do
        rendered[#rendered + 1] = line
      end
    end
  end

  if req.lines then
    rendered = slice(rendered, req.lines[1], req.lines[2])
  end
  emit(rendered)
end

--- Search tag names and heading titles across in-scope help files.
---@param req table
---@param index table
local function cmd_find(req, index)
  local matcher = build_matcher(strip_markers(req.pattern))
  local results = {}
  for _, doc in ipairs(index.order) do
    if req.scope == "all" or doc.scope == req.scope then
      local lines, text, root = parse_file(doc.path)
      for _, entry in ipairs(index.tags_by_doc[doc.path] or {}) do
        if matcher(entry.name) then
          local row = find_tag_row(lines, entry.name)
          if row then
            results[#results + 1] =
              { stem = doc.stem, line = row + 1, name = entry.name }
          end
        end
      end
      for _, heading in ipairs(collect_headings(root, text)) do
        if matcher(heading.title) then
          results[#results + 1] =
            { stem = doc.stem, line = heading.heading_row + 1, name = heading.title }
        end
      end
    end
  end

  table.sort(results, function(a, b)
    if a.stem:lower() ~= b.stem:lower() then
      return a.stem:lower() < b.stem:lower()
    end
    if a.line ~= b.line then
      return a.line < b.line
    end
    return a.name < b.name
  end)

  local seen = {}
  local out = {}
  for _, result in ipairs(results) do
    local key = result.stem .. "\0" .. result.line .. "\0" .. result.name
    if not seen[key] then
      seen[key] = true
      out[#out + 1] = result.stem .. ".txt:" .. result.line .. ": " .. result.name
    end
  end
  emit(out)
end

-- ------------------------------------------------------------------------------
-- Entry point

--- Bail if nvim lacks the bundled `vimdoc` treesitter parser.
local function assert_vimdoc_available()
  local ok, err = pcall(vim.treesitter.get_string_parser, "", "vimdoc")
  if not ok then
    fail("nvim is missing the bundled 'vimdoc' treesitter parser; upgrade nvim ("
      .. tostring(err) .. ")")
  end
end

--- Decode the JSON request and dispatch to the matching subcommand.
local function main()
  local raw = arg[1]
  if not raw then
    fail("missing JSON request argument")
  end
  local ok, req = pcall(vim.json.decode, raw)
  if not ok then
    fail("invalid JSON request: " .. tostring(req))
  end
  assert_vimdoc_available()

  local index = build_index()
  if req.command == "tag" then
    cmd_tag(req, index)
  elseif req.command == "toc" then
    cmd_toc(req, index)
  elseif req.command == "section" then
    cmd_section(req, index)
  elseif req.command == "find" then
    cmd_find(req, index)
  else
    fail("unknown command: " .. tostring(req.command))
  end
end

main()
