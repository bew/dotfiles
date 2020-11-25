> Ref: https://nixos.org/manual/nixpkgs/stable/#sec-overlays-lookup

The list of overlays is determined as follows.

1. First, if an overlays argument to the Nixpkgs function itself is given, then that is used and no path lookup will be performed.

2. Otherwise, if the Nix path entry `<nixpkgs-overlays>` exists, we look for overlays at that path, as described below.

   See the section on NIX_PATH in the Nix manual for more details on how to set a value for `<nixpkgs-overlays>`.

3. If one of ~/.config/nixpkgs/overlays.nix and ~/.config/nixpkgs/overlays/ exists, then we look for overlays at that path, as described below. It is an error if both exist.

If we are looking for overlays at a path, then there are two cases:

- If the path is a file, then the file is imported as a Nix expression and used as the list of overlays.

- If the path is a directory, then we take the content of the directory, order it lexicographically, and attempt to interpret each as an overlay by:

  - Importing the file, if it is a .nix file.

  - Importing a top-level default.nix file, if it is a directory.

Because overlays that are set in NixOS configuration do not affect non-NixOS operations such as nix-env, the overlays.nix option provides a convenient way to use the same overlays for a NixOS system configuration and user configuration: the same file can be used as overlays.nix and imported as the value of nixpkgs.overlays.


