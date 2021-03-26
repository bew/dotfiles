# home-manager template

This is an attempt to write and manage my home configs with Nix, using the
[home-manager](https://github.com/nix-community/home-manager) module system.

`home-manager` is a great way to manage dotfiles in a reproducible way.

# Prerequisites

You must have [Nix](https://nixos.org) installed on your machine.

```sh
curl -L https://nixos.org/nix/install | sh
```

# Bootstrap

[`just`](https://github.com/casey/just) is used as a command runner to build & activate the home config.

On the first install, `just` is not in the $PATH, so we use Nix to download and run it (without installing):
```sh
nix run nixpkgs/nixpkgs-unstable#just -- switch
```
This downloads `just` from the current unstable branch of nixpkgs,
and run `just switch` to build and switch to the home config described in this repo.
