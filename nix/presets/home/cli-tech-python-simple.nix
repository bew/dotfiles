{ pkgsets, mypkglib, ... }:

let
  inherit (pkgsets) stable;
in {
  home.packages = [
    stable.python3
    (let
      ipythonEnv = pyPkg: pyPkg.withPackages (pypkgs: [
        pypkgs.ipython
        # Rich extension is used for nicer UI elements
        # See: https://rich.readthedocs.io/en/stable/introduction.html#ipython-extension
        pypkgs.rich
      ]);
    in mypkglib.linkSingleBin "${ipythonEnv stable.python3}/bin/ipython")
  ];
}
