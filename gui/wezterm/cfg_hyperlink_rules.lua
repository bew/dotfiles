local wezterm = require"wezterm"
local mytable = require "lib/mystdlib".mytable

local cfg = {}

---@type HyperlinkRule[]
cfg.hyperlink_rules = wezterm.default_hyperlink_rules()

---@class HyperlinkRule
---@field regex string
---@field format string

--- Add the given hyperlink rule or rules
---@param rules HyperlinkRule|HyperlinkRule[]
local function add_rule(rules)
  if not mytable.is_list(rules) then
    rules = {rules}
  end
  for _, rule in ipairs(rules) do
    table.insert(cfg.hyperlink_rules, rule)
  end
end

-- Match `gh"owner/repo"` as a github user/repo URL
-- (this the syntax I use for declaring Neovim plugins in my config)
add_rule {
  regex = [[gh"([\w\d][-\w\d\._]+)/([-\w\d\._]+)"]],
  format = "https://www.github.com/$1/$2",
}

-- Match `uses: owner/repo@rev` as a github user/repo URL at rev/tag
-- (this the syntax used for using external Github actions)
add_rule {
  regex = [[uses: ([\w\d][^/]+)/([^@]+)@([\w\d\._-]+)]],
  format = "https://www.github.com/$1/$2/tree/$3",
}

-- Match `github:owner/repo` & `github:owner/repo/branch` as a github URL
-- (this is the syntax used for Nix flake github references)
add_rule {
  {
    regex = [[github:([\w\d][^/"'`]+)/([^/"'`]+)]],
    format = "https://www.github.com/$1/$2",
  },
  {
    regex = [[github:([\w\d][^/"'`]+)/([^/"'`]+)/([^"'`]+)]],
    format = "https://www.github.com/$1/$2/tree/$3",
  },
}

return cfg
