#!/usr/bin/env bash

# Re-adjust horizontal split to a configured ratio for 2-column layouts.
# Works with multiple splits within each column.
#
# Features:
# - Smart detection of 2-column layouts
# - Works with multiple vertical splits in each column
# - Preserves vertical splits within columns (only adjusts horizontal boundary)
# - Width threshold check (window must be wide enough)
# - Clear error messages for all failure cases
# - Shows actual achieved ratio in success message
#
# Example layouts that work:
#   ┌────┬────┐     ┌────┬────┐     ┌────┬────┐
#   │    │    │     │ A  │ C  │     │ A  │ D  │
#   │ A  │ B  │     ├────┤    │     ├────┼────┤
#   │    │    │     │ B  │    │     │ B  │ E  │
#   └────┴────┘     └────┴────┘     ├────┤    │
#   2 columns       2 columns       │ C  │    │
#                   left split      └────┴────┘
#                                   both split

# Configuration - read from tmux user variables (with fallback)
THRESHOLD=$(tmux show-options -gv @wide_layout_split_threshold 2>/dev/null || echo "240")
TARGET_RATIO=$(tmux show-options -gv @wide_layout_split_ratio 2>/dev/null || echo "36")

# Get window dimensions
window_width=$(tmux display-message -p "#{window_width}")

# Check width threshold (must be GREATER than threshold)
if [[ "$window_width" -le "$THRESHOLD" ]]; then
    echo >&2 "WARNING: Window too narrow for re-adjustment (<=${THRESHOLD} chars)"
    exit 0
fi

# Get all unique pane_left values (represents distinct columns)
# Sort numerically to ensure proper ordering
pane_lefts=$(tmux list-panes -F "#{pane_left}" | sort -n -u)
# Count how many distinct columns we have (number of lines in output)
num_columns=$(echo "$pane_lefts" | wc -l | tr -d ' ')

# Check if it's a 2-column layout
if [[ "$num_columns" != 2 ]]; then
    echo >&2 "WARNING: Not a 2-column layout (found ${num_columns} column(s))"
    exit 0
fi

# Verify first column starts at x=0
first_col=$(echo "$pane_lefts" | head -1)
if [[ "$first_col" != 0 ]]; then
    echo >&2 "ERROR: Invalid layout: first column doesn't start at x=0"
    exit 1
fi

# Calculate target split position (left column target width)
target_width=$((window_width * TARGET_RATIO / 100))

# Get the first pane in the left column (to use as resize target)
# All panes in the same column (same pane_left value) will resize together automatically
# This is how tmux's resize-pane -x works: it resizes all panes in the same vertical stack
left_pane=$(tmux list-panes -F "#{?#{==:#{pane_left},0},#{pane_id},}" | grep -v '^$' | head -1)

# Sanity check: ensure we found a left pane
if [[ -z "$left_pane" ]]; then
    echo >&2 "ERROR: Could not find left column pane"
    exit 1
fi

# Resize the left column to target width
# This resizes ALL panes with pane_left=0 simultaneously
tmux resize-pane -t "$left_pane" -x "$target_width"

# Display success message with actual horizontal ratio achieved
actual_width=$(tmux display-message -p -t "$left_pane" "#{pane_width}")
right_width=$((window_width - actual_width - 1))  # -1 for border
left_percent=$((actual_width * 100 / window_width))
right_percent=$((right_width * 100 / window_width))
echo >&2 "SUCCESS: Layout re-adjusted to ${left_percent}%:${right_percent}% horizontal ratio"
