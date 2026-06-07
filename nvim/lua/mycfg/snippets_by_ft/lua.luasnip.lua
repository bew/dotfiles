-- vim:set ft=lua.luasnip:
local ls = require"luasnip"
local SU = require"mycfg.snippets_by_ft._utils" -- Snip Utils

local SNIPS = {}
local snip = SU.get_snip_fn(SNIPS)

local i = ls.insert_node ---@diagnostic disable-line: unused-local
local t = ls.text_node ---@diagnostic disable-line: unused-local

-- Start of snippets definitions

snip("s", { desc = "Define a snippet" }, SU.myfmt {
  [[
    snip("<trigger>", { desc = "<desc>"<more_opts> }, <nodes><snip_opts>)
  ]],
  {
    trigger = i(1, "trig"),
    desc = i(2, "TODO: desc!"),
    more_opts = i(3),
    nodes = i(4),
    snip_opts = ls.choice_node(5, {
      t"",
      SU.myfmt {
        [[
          , {
          	stored = {
          		<kv>,
          	}
          }
        ]],
        { kv = i(1) }
      }
    })
  }
})

snip("lss", { desc = "Standard LuaSnip snippet def" }, SU.myfmt {
  [[ls.snippet("<trig>", {<nodes>})]],
  { trig = i(1), nodes = i(2) },
})

snip("lsf", { desc = "Standard Luasnip fmta <…>" }, ls.choice_node(1, {
  SU.myfmt {
    [==[fmta([[<template>]], {<nodes>})]==],
    {
      template = ls.restore_node(1, "fmt_template"),
      nodes = ls.restore_node(2, "fmt_nodes"),
    },
  },
  SU.myfmt {
    [==[
      fmta(
        [[<template>]],
        {<nodes>}
      )
    ]==],
    {
      template = ls.restore_node(1, "fmt_template"),
      nodes = ls.restore_node(2, "fmt_nodes"),
    },
  }
}), {
  stored = {
    -- Keys for ls.restore_node
    -- (used to share nodes between choice node branches ✨)
    fmt_template = i(nil),
    fmt_nodes = i(nil),
  },
})

--------------------------
-- Snippet nodes snippets

---@param node_no integer
local function mk_snip_idx_node(node_no)
  return i(node_no, "nil")
end

local function mk_fmt_nodes()
  local function mk_eq_node()
    -- Node that detects whether the snippet template includes `[[` or `]]`,
    -- requiring `[==[ foo [[ bar ]] baz ]==]` to avoid breaking the syntax ✨✨
    return ls.function_node(
      function(given_nodes_text)
        local template_lines = given_nodes_text[1]
        local has_double_sq_brackets = vim.iter(template_lines)
          :any(function(line)
            local match = line:find"%[%[" or line:find"%]%]"
            print("DEBUG", "line:", vim.inspect(line), "match:", vim.inspect(match))
            return match
          end)
        if has_double_sq_brackets then
          return "=="
        else
          return ""
        end
      end,
      {SU.node_ref"snip-template"}
    )
  end
  return ls.choice_node(1, {
    SU.myfmt {
      [==[SU.<fmt_fn> { [<eq>[<template>]<eq>], { <nodes> } }]==],
      {
        eq = mk_eq_node(),
        fmt_fn = ls.restore_node(1, "fmt_fn"),
        template = ls.restore_node(2, "fmt_template"),
        nodes = ls.restore_node(3, "fmt_nodes"),
      }
    },
    SU.myfmt {
      [==[
        SU.<fmt_fn> {
          [<eq>[<template>]<eq>],
          {<nodes>},
        }
      ]==],
      {
        eq = mk_eq_node(),
        fmt_fn = ls.restore_node(1, "fmt_fn"),
        template = ls.restore_node(2, "fmt_template"),
        nodes = ls.restore_node(3, "fmt_nodes"),
      }
    },
  }, { restore_cursor = true })
end

snip("f", { desc = "SU.myfmt { .. }" }, mk_fmt_nodes(), {
  stored = {
    -- Keys for ls.restore_node
    -- (used to share nodes between choice node branches ✨)
    fmt_fn = t"myfmt",
    fmt_template = i(nil, nil, {key="snip-template"}),
    fmt_nodes = i(nil),
  },
})

snip("fmt", { desc = "SU.myfmt* { .. }" }, mk_fmt_nodes(), {
  stored = {
    -- Keys for ls.restore_node
    -- (used to share nodes between choice node branches ✨)
    fmt_fn = ls.choice_node(nil, {
      t"myfmt",
      t"myfmt_braces",
      t"myfmt_no_strip",
      t"myfmt_braces_no_strip",
    }),
    fmt_template = i(nil, nil, {key="snip-template"}),
    fmt_nodes = i(nil),
  },
})

snip("t", { desc = "ls.text_node" }, SU.myfmt {
  [[t"<txt>"]],
  { txt = i(1) },
})

snip("i", { desc = "ls.insert_node" }, SU.myfmt {
  [[i(<no><after>)]],
  {
    no = mk_snip_idx_node(1),
    after = ls.choice_node(2, {
      SU.myfmt {
        [[, "<default>"<opts>]],
        {
          default = i(1, "TODO"),
          opts = i(2),
        },
      },
      t"",
    }),
  },
})

snip("sn", { desc = "ls.snippet_node" }, SU.myfmt {
  [[ls.snippet_node(<no>, <nodes>)]],
  {
    no = mk_snip_idx_node(1),
    nodes = i(2),
  },
})

snip("c", { desc = "ls.choice_node" }, SU.myfmt {
  [[ls.choice_node(<no>, {<choices>}<opts>)]],
  {
    no = mk_snip_idx_node(1),
    choices = i(2),
    opts = ls.choice_node(3, {
      t"",
      SU.myfmt {
        [[, {<opts><more>}]],
        { opts = i(1), more = i(0) },
      }
    }),
  },
})

snip("rn", { desc = "ls.restore_node" }, SU.myfmt {
  [[ls.restore_node(<no>, "<stored_key>"<opts>)]],
  {
    no = mk_snip_idx_node(1),
    stored_key = i(2, "todo:stored-key"),
    opts = i(3),
  },
})

snip("nr", { desc = "SU.(maybe_)node_ref" }, ls.choice_node(1, {
  -- note: I never use the other form of node ref (by idx / absolute idx path)
  -- so only having named key ref is okay.
  SU.myfmt {
    [[SU.node_ref"<ref>"]],
    { ref = ls.restore_node(1, "ref") },
  },
  SU.myfmt {
    [[SU.maybe_node_ref"<ref>"]],
    { ref = ls.restore_node(1, "ref") },
  },
}), {
  stored = {
    ref = i(nil, "todo:node-key"),
  },
})

---@param opts {fn_name: string, maybe_no: LuaSnip.Node}
local function mk_dyn_fn_nodes(opts)
  return SU.myfmt {
    [[
      ls.<fn>(<maybe_no>function(<nodes_txt><comma><more_args>)
        <body>
      end<node_refs>)
    ]],
    {
      fn = t(opts.fn_name),
      maybe_no = opts.maybe_no,
      nodes_txt = ls.function_node(function(ref_nodes_txt)
        local has_node_refs = ref_nodes_txt[1][1] ~= ""
        local has_more_args = ref_nodes_txt[2][1] ~= ""
        if has_node_refs or has_more_args then
          return "ref_nodes_txt"
        else
          return ""
        end
      end, {SU.node_ref"node_refs", SU.node_ref"more_args"}),
      comma = ls.function_node(function(ref_nodes_txt)
        local has_more_args = ref_nodes_txt[1][1] ~= ""
        if has_more_args then
          return ", "
        else
          return ""
        end
      end, {SU.node_ref"more_args"}),
      node_refs = ls.choice_node(1, {
        SU.myfmt {
          [[, {<node_refs>}]],
          { node_refs = i(1, nil, {key="node_refs"}) },
        },
        t"",
      }),
      more_args = ls.choice_node(2, {
        t"parent_node, user_args",
        t"parent_node",
        t"",
      }, {key="more_args"}),
      body = i(3),
      -- MAYBE(LATER): in body, based on node_refs we could generate access to referenced nodes...
    },
  }
end

-- (note: cannot use `fn` as trigger, would override my function snips!)
snip("fnn", { desc = "ls.function_node" }, mk_dyn_fn_nodes {
  fn_name = "function_node",
  maybe_no = t"",
})

snip("dn", { desc = "ls.dynamic_node" }, mk_dyn_fn_nodes {
  fn_name = "dynamic_node",
  maybe_no = SU.myfmt { [[<no>, ]], { no = mk_snip_idx_node(1) } },
})

-- End of snippets definitions

return SNIPS, {} -- snippets, autosnippets
