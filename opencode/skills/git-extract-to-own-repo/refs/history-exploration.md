# History exploration

Fallback reference for `Phase:Recon`.
Use it only when `bash "<skill-dir>/scripts/recon"` did not run,
or when its all-branch history output needs interpretation.

## Commands

```sh
# tracked files under the part
git -C "$srcroot" ls-files -- "$parts"
# commits touching the part, current branch / all branches
git -C "$srcroot" log --oneline -- "$parts"
git -C "$srcroot" log --all --oneline -- "$parts"
# count both, to spot history on other branches
git -C "$srcroot" log --oneline -- "$parts" | wc -l
git -C "$srcroot" log --all --oneline -- "$parts" | wc -l
# per-file lineage across renames
git -C "$srcroot" log --follow --oneline -- <file>
# renames inside the part
git -C "$srcroot" log --oneline --name-status --diff-filter=R -- "$parts"
# prior locations of a basename anywhere in history (scattered lineage)
git -C "$srcroot" log --all --oneline --name-only -- '*<basename>'
# earliest commit that created the now-standalone dir (project-era start)
git -C "$srcroot" log --oneline --reverse -- "$parts"
# branch relationship (is A an ancestor of B?)
git -C "$srcroot" merge-base --is-ancestor <A> <B> && echo ancestor
git -C "$srcroot" log --oneline <A>..<B> -- "$parts"
# consumer references (fallback if the script could not run)
rg -n -- "$parts" "$srcroot"
git -C "$srcroot" grep -n -- "$parts"
# lockfile hits
for f in flake.lock package-lock.json Cargo.lock go.sum poetry.lock; do
    [[ -f "$srcroot/$f" ]] && grep -qF -- "$parts" "$srcroot/$f" && echo "lockfile hit: $f"
done
```

## Branch resolution

At `Phase:Decide`, choose `$branches` — one or more, user choice:
- If the all-branch commit count exceeds the current-branch count, or prior locations appear
  on other branches: ask the user which branch(es) to extract.
- Otherwise default to the current branch.

## History depths

Offer these three in `Phase:Decide`:

- **Current path only** — `git log -- "$parts"`.
- **Dedicated-project era** — from the first commit that made the part a self-contained dir.
- **Full scattered lineage** — when files lived under unrelated paths earlier; messy to merge.
