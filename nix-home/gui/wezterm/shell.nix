let

  pkgs = import <nixpkgs> {};

in pkgs.mkShell {
  buildInputs = import ./deps.nix { inherit pkgs; } ++ [
    pkgs.cargo
    pkgs.rustc
    pkgs.pkg-config
  ];
}
