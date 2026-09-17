{ lib, pkgs }:

let
  # Symlink core: builds a Symlink redirect for a resolved Root.
  mkSymlinkRedirect = pkgs.callPackage ./symlink-redirect.nix { };

  # Roots as a list of `{ name, nixStorePath, realPath, mode }`, tagging each with its name.
  rootList = roots:
    lib.mapAttrsToList (name: root: root // { inherit name; }) roots;

  # True when `base` is a path-component prefix of `p` (or equal to it).
  # Ensures `/nix/store/aaa-srcX` does NOT match a root at `/nix/store/aaa-src`.
  isPathPrefix = base: p:
    let
      baseStr = toString base;
      pStr = toString p;
    in
    pStr == baseStr || lib.hasPrefix "${baseStr}/" pStr;

  # Roots sorted by nixStorePath length, longest first, so the first matching
  # Root is the most specific (a nested Root beats its parent).
  rootsByLongest = roots:
    lib.sort
      (a: b: builtins.stringLength (toString a.nixStorePath) > builtins.stringLength (toString b.nixStorePath))
      (rootList roots);

  # The longest Root whose nixStorePath is a path-component prefix of `givenPath`.
  findWinner = sortedRoots: givenPath:
    lib.findFirst (root: isPathPrefix root.nixStorePath givenPath) null sortedRoots;

  # Fail eval if two Roots share a nixStorePath: resolution would be ambiguous,
  # and (with path-component matching) this is the only possible ambiguity.
  checkNoDuplicateStorePaths = roots:
    let
      storePaths = map (root: toString root.nixStorePath) (rootList roots);
      duplicates = lib.filter (sp: lib.count (x: x == sp) storePaths > 1) (lib.unique storePaths);
    in
    if duplicates != [ ] then
      throw "dynpaths: duplicate root nixStorePath(s): ${lib.concatStringsSep ", " duplicates}"
    else
      null;
in

# Build a `mkLink` function for the given Roots and global mode.
# `mkLink givenPath` returns a Symlink redirect when the winning Root's Effective
# mode is dynamic, and the given path unchanged (a Store copy) otherwise.
{ roots, globalMode }:

let
  # A Root's mode wins when set, otherwise the global mode applies.
  effectiveMode = root: if root.mode != null then root.mode else globalMode;

  sortedRoots = rootsByLongest roots;

  mkLink = givenPath:
    let
      winner = findWinner sortedRoots givenPath;
    in
    if winner == null then
      givenPath # No Root matches: silent Store-copy fallback.
    else if effectiveMode winner != "dynamic" then
      givenPath
    else
      mkSymlinkRedirect { inherit (winner) name nixStorePath realPath; } givenPath;
in

# Force the duplicate check eagerly, so it fails at eval time
# regardless of whether `mkLink` is ever applied.
builtins.seq (checkNoDuplicateStorePaths roots) mkLink
