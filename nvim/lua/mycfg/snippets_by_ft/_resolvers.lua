local SU = require"mycfg.snippets_by_ft._utils" -- Snip Utils

local SR = {}

--- Remove extra spaces after trigger, to always leave cursor 'after space' after snip expansion.
SR.delete_spaces_after_trigger = SU.mk_expand_params_resolver { delete_after_trig = "^%s+" }

return SR
