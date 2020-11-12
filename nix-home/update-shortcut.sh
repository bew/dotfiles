hm_src=$(nix eval --raw '(import ./nix/sources.nix).home-manager')
ln --no-dereference -fs "$hm_src" hm-src.link

nixpkgs_src=$(nix eval --raw '(import ./nix/sources.nix).nixpkgs')
ln --no-dereference -fs "$nixpkgs_src" nixpkgs-src.link
