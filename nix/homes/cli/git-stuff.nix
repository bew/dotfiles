{ pkgsChannels, pkgs, ... }:

let
  inherit (pkgsChannels) stable bleedingedge;
in {
  home.packages = [
    (pkgs.buildEnv {
      name = "git-bew-env";
      paths = [
        stable.git
        # config tools
        bleedingedge.delta # for nice git diffs
        stable.onefetch # repo global info
        # extra commands
        stable.git-lfs # store specific (large) files out-of-repo
        stable.git-trim # auto delete merged branches
        stable.git-absorb # automatic `git commit --fixup` on relevant commits
        # other tools
        stable.gh # github cli for view & operations
      ];
      meta.mainProgram = "git";
    })
  ];
}
