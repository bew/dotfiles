{
  git,
  delta,
  onefetch,
  mergiraf,
  git-lfs,
  git-trim,
  git-absorb,
  gh,
  lazygit,

  # build deps
  buildEnv,
}:

buildEnv {
  name = "git-bew-env";
  paths = [
    git

    # config tools
    delta # for nice git diffs
    onefetch # repo global info
    mergiraf # Treesitter-based conflict solver

    # extra commands
    git-lfs # store specific (large) files out-of-repo
    git-trim # auto delete merged branches
    git-absorb # automatic `git commit --fixup` on relevant commits

    # other tools
    gh # github cli for view & operations
    lazygit
  ];
  meta.mainProgram = "git";
}
