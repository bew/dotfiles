{
  lib,
  callPackage,
  writeShellScript,
  fetchpatch,

  eza,
}:

let
  mypkglib = callPackage ../../nix/mypkglib.nix {};

  # SGR foreground spec, from the 256-color palette
  fg = n: "38;5;${toString n}";
  fgBold = n: "38;5;${toString n};1";

  # Config eza colors to shades of grey instead of a distractful bright colors
  # Read more at `man 5 eza_colors`
  colorsNamedGroups = {
    date = {
      da = fg 243; # darker date
    };

    userGroup = {
      uu = fg 239; gu = fg 239; # darker user/group that is me
      un = fg 250; gn = fg 250; # white(visible!) user/group that is not me / am not part of
      uR = fg 124; gR = fg 124; # dark red user/group that is 'root'
    };

    # Color file sizes by order of magnitude
    size = {
      nb = fg 239; ub = fg 241;     #  0  -> <1KB : grey
      nk = fg 29;  uk = fg 100;     # 1KB -> <1MB : green
      nm = fg 26;  um = fg 32;      # 1MB -> <1GB : blue
      ng = fg 130; ug = fgBold 166; # 1GB -> <1TB : orange
      nt = fg 160; ut = fgBold 197; # 1TB -> +++  : red
    };

    # Darker permissions (shades of grey)
    permissions = {
      ur = fg 240; uw = fg 244; ux = fg 248; ue = fg 248; # user permissions
      gr = fg 240; gw = fg 244; gx = fg 248; # group permissions
      tr = fg 240; tw = fg 244; tx = fg 248; # other permissions
    };

    markers = {
      xa = fg 24;  # xattr marker ('@')
      xx = fg 240; # punctuation ('-')
    };

    # TODO: Enable git column with darker colors as well?
    # FIXME(request): Ask to make configurable git symbols
    #   (e.g. I don't like `N` for untracked => would prefer `U` (grey);
    #    and instead of `U` for conflicts => would prefer `X` (red))
  };
  # Shell lines setting EZA_COLORS, one `+=` per named group, with the group name as a comment above.
  # NOTE: group names are organizational only, eza parses EZA_COLORS order-independently.
  colorsEnvSpec = lib.concatMapStrings (line: "${line}\n") (lib.flatten (lib.mapAttrsToList
    (groupName: group: [
      "# ${groupName} colors"
      ''EZA_COLORS+="${lib.concatStringsSep ":" (lib.mapAttrsToList (code: style: "${code}=${style}") group)}:"''
    ])
    colorsNamedGroups));

  ezaDrv = eza.overrideAttrs (prev: {
    doCheck = false;
    patches = prev.patches ++ [
      (fetchpatch {
        # Commit: fix(color-scale): use file size unit custom color when not using color scale
        # PR: https://github.com/eza-community/eza/pull/975
        url = "https://github.com/eza-community/eza/commit/c7493753fbf8d572703a782941cf134357dd740a.patch";
        hash = "sha256-lmXGt20l6o5tbNXDicq17sBCt36qckV8XX7EJ2Gi3vQ=";
      })
    ];
  });
in

mypkglib.replaceBinsInPkg {
  name = "eza-bew";
  copyFromPkg = ezaDrv;
  meta.mainProgram = "eza";
  bins = {
    eza = writeShellScript "eza" ''
      EZA_COLORS=""
      ${colorsEnvSpec}
      export EZA_COLORS
      exec ${lib.getExe ezaDrv} "$@"
    '';
  };
}
