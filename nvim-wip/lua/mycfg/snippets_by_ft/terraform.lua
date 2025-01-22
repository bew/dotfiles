-- vim:set ft=lua.luasnip:
local ls = require"luasnip"
local SU = require"mycfg.snippets_by_ft._utils" -- Snip Utils

local SNIPS = {}
local snip = SU.get_snip_fn(SNIPS)

local i = ls.insert_node ---@diagnostic disable-line: unused-local
local t = ls.text_node ---@diagnostic disable-line: unused-local

-- Start of snippets definitions

snip("r", { desc = "resource block" }, SU.myfmt {
  [[
    resource "<type>" "<name>" {
      <params>
    }
  ]],
  {
    type = i(1),
    name = i(2),
    params = i(3),
  }
})

snip("dyn", { desc = "dynamic block" }, SU.myfmt {
  [[
    dynamic "<name>" {
      for_each = <iterable>
      iterator = <iterator_name>
      content {
        <params>
      }
    }
  ]],
  {
    name = i(1),
    iterable = i(2),
    iterator_name = i(3, "it"),
    params = i(4),
  }
})

snip("d", { desc = "datasource block" }, SU.myfmt {
  [[
    data "<type>" "<name>" {
      <params>
    }
  ]],
  {
    type = i(1),
    name = i(2),
    params = i(3),
  }
})

snip("l", { desc = "locals block" }, SU.myfmt {
  [[
    locals {
      <local_vars>
    }
  ]],
  {
    local_vars = i(1),
  }
})

snip("v", { desc = "variable block" }, SU.myfmt {
  [[
    variable "<name>" {
      description = "<desc>"
      type        = <type>
      nullable    = <nullable><more>
    }
  ]],
  {
    name = i(1, "var_name"),
    type = i(2, "string"),
    desc = i(3, "TODO: add desc!"),
    nullable = ls.choice_node(4, {
      t"false",
      t"true",
    }),
    more = i(5),
  }
})

snip("valid", { desc = "validation block (for var)" }, SU.myfmt {
  [[
    validation {
      condition     = <cond>
      error_message = "<err>"
    }
  ]],
  {
    cond = i(1, "true"),
    err = i(2, "TODO: write error message!"),
  }
})

snip("o", { desc = "output block" }, SU.myfmt {
  [[
    output "<name>" {
      value = <value>
    }
  ]],
  {
    name = i(1),
    value = i(2),
  }
})

snip("pr", { desc = "provider block" }, SU.myfmt {
  [[
    provider "<name>" {<params>}
  ]],
  {
    name = i(1),
    params = i(2),
  }
})

snip("tfp", { desc = "tf required_providers config" }, SU.myfmt {
  [[
    terraform {
      required_providers {
        <name> = {
          source  = "<source>"
          version = "<constraint> <version>"
        }<more>
      }
    }
  ]],
  {
    name = i(1),
    source = i(2),
    constraint = t"~>",
    version = i(3),
    more = i(4),
  }
})

snip("tfb", { desc = "tf backend config" }, SU.myfmt {
  [[
    terraform {
      backend "<kind>" {
        <params>
      }
    }
  ]],
  {
    kind = i(1, "local"),
    params = i(2),
  }
})

snip("mv", { desc = "decl moved refactoring" }, SU.myfmt {
  [[
    moved {
      from = <from>
      to   = <to>
    }
  ]],
  {
    from = i(1),
    to = i(2),
  }
})

snip("im", { desc = "decl import" }, SU.myfmt {
  [[
    import {
      to = <to>
      id = "<id>"
    }
  ]],
  {
    to = i(1),
    id = i(2),
  }
})

-- End of snippets definitions

return SNIPS, {} -- snippets, autosnippets
