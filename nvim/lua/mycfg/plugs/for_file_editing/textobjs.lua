local PluginSystem = require"mylib.plugin_system"
local t = PluginSystem.tags
local gh = PluginSystem.sources.github
-- local myplug = PluginSystem.sources.myplug
local Plug = PluginSystem.get_plugin_declarator {
  default_tags = { t.textobj },
}

--------------------------------

Plug {
  source = gh"echasnovski/mini.ai",
  desc = "Extend and create `a`/`i` textobjects",
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    require"mini.ai".setup {
      search_method = "cover_or_next",
    }
  end,
}

--------------------------------

Plug.lib_textobj_user {
  source = gh"kana/vim-textobj-user",
  tags = {t.vimscript, t.lib_only},
}

-- textobj: ii ai iI aI
Plug {
  source = gh"kana/vim-textobj-indent",
  desc = "Indent-based text object",
  tags = {t.vimscript},
  depends_on = { Plug.lib_textobj_user },
  defer_load = { on_event = "VeryLazy" },
}

-- textobj: ic ac
Plug {
  source = gh"glts/vim-textobj-comment",
  desc = "Comment text object",
  tags = {t.vimscript},
  depends_on = { Plug.lib_textobj_user },
  -- IDEA: when the comment is the last thing of the line,
  -- `Ac` could also take the spaces before it!
  -- Meaning that when I have:
  -- `foobar  -- |some comment`
  -- Doing `dAc` currently does:
  -- `foobar  ` (trailing spaces left!)
  -- I'd like to have:
  -- `foobar`
  defer_load = { on_event = "VeryLazy" },
}

-- textobj: ie ae
--   ae is the entire buffer content
--   ie is like ae without leading/trailing blank lines
Plug {
  source = gh"kana/vim-textobj-entire",
  desc = "Entire-buffer-content text object",
  tags = {t.vimscript},
  depends_on = { Plug.lib_textobj_user },
  defer_load = { on_event = "VeryLazy" },
}

-- textobj: i<Space> a<Space>
--   a<Space> is all whitespace
--   i<Space> is same as a<Space> except it leaves a single space or newline
Plug {
  source = gh"vim-utils/vim-space",
  desc = "Whitespace text object",
  tags = {t.vimscript},
  defer_load = { on_event = "VeryLazy" },
}
