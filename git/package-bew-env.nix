{
  git,

  # Tools
  delta,
  onefetch,
  mergiraf,
  git-lfs,
  git-trim,
  git-absorb,
  gh,
  lazygit,
  worktrunk,
  git-filter-repo,

  # build deps
  lib,
  buildEnv,
  callPackage,
}:

let
  mypkglib = callPackage ../nix/mypkglib.nix {};
in buildEnv {
  name = "git-bew-env";
  paths = [
    # git drv has many useless bins (for backward compat I think)
    # I only need `git` bin + other related files (man pages, ..)
    (mypkglib.replaceBinsInPkg {
      name = "git-only";
      copyFromPkg = git;
      meta.mainProgram = "git";
      bins = { git = lib.getExe git; };
    })

    # config tools
    delta # for nice git diffs
    onefetch # repo global info
    mergiraf # Treesitter-based conflict solver

    worktrunk # Manage worktrees ✨

    # extra commands
    git-lfs # store specific (large) files out-of-repo
    git-trim # auto delete merged branches
    git-absorb # automatic `git commit --fixup` on relevant commits
    git-filter-repo # better filter-branch (even recommanded in `man git-filter-branch`!)

    # other tools
    gh # github cli for view & operations
    lazygit
  ];
  meta.mainProgram = "git";
}
