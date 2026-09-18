# `Phase:Extract` — clone and filter

Never filter the source in place.
Always clone first.

Exactly one selected branch:
```sh
# local clones hardlink objects -> filter-repo refuses; use --no-local
git clone --no-local --single-branch --branch "${branches[0]}" "$srcroot" "$dest"
git -C "$dest" filter-repo \
  --path <p1>/ --path-rename <p1>/: \
  --refs "refs/heads/${branches[0]}" --force
```

Several selected branches (clone without `--single-branch`, pass every selected ref):
```sh
git clone --no-local "$srcroot" "$dest"
git -C "$dest" filter-repo \
  --path <p1>/ --path-rename <p1>/: \
  --refs refs/heads/<b1> refs/heads/<b2> --force
```

Pick the form matching the branch count chosen in `Phase:Decide`.

Notes and gotchas:
- `--subdirectory-filter <d>` ≡ `--path <d>/ --path-rename <d>/:`;
  empty new name strips the prefix to root.
- Merge sibling dirs (old + new names) by pairing each `--path` with its own `--path-rename`.
- Local clone without `--no-local` hardlinks objects; then filter-repo needs `--force`.
- An empty root commit can survive. Drop it with `git filter-repo --prune-empty always --force`.

Then reset refs and attach the new remote:
```sh
git -C "$dest" remote remove origin          # drop source remote + tracking refs
git -C "$dest" branch -m main                # or the agreed default branch name
git -C "$dest" remote add origin "$remote"   # only if $remote != (none); never push
```

Verify:
```sh
git -C "$dest" log --oneline
git -C "$dest" ls-files
git -C "$dest" status --short
git -C "$dest" for-each-ref --format='%(refname)'
```
Confirm the tree is at root, the history matches the chosen depth,
and no stale remote-tracking refs remain.

Ready to move to `Phase:Rewire`? (say 'next' or similar to proceed)
