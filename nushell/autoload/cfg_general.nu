# Ensure shell histories are per-shell (don't mix!)
$env.config.history.sync_on_enter = false
$env.config.history.isolation = false

# GRR: fuzzy completion is basically useless since there is no serious scoring system..
# $env.config.completions.algorithm = "fuzzy"

# Maximum external commands retrieved from PATH (WHY is there a limit..)
$env.config.completions.external.max_results = 1000
