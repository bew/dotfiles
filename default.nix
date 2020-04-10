#
# Wanted: describe my dotfiles in a way that can be installed/managed by Nix if wanted
#
# I want to choose what I 'install' from my dotfiles (with options).
# I want to be able to edit some files and immediately test the changes, in a dev-env.
#
# With Nix, I want to "deploy" my dotfiles in multiple directories, to test different
# things in parallel (e.g: from different branches), using `HOME=some_path binary` or
# maybe even using a pure nix-shell (let's be crazy).
#
# I want to be able to split work-only, fun-only, headless-only (no gui) configs to
# compose them easily.
#
# I don't want to write a nix file for every packages (e.g: only one for all gui configs)
# (may change later)
#
# I want an 'activation script' (similar to NixOS) to deploy a 'generation' of my dotfiles
# to a specific directory (e.g: my home directory) without force-breaking existing symlinks
# (give an error and rollback).
#
#
# I want composable dotfiles, I may have part of my dotfiles public, another in a private
# repository (with work creds, scripts, ...), some parts here and there..
#
# I want to be able to easily deploy a minimal zsh & nvim config on a new VPS server (+ a few tools). (or for a new user)
#
#
# Steps:
# A simple nvim config derivation with the 'put everything (e.g: whole nvim dir) in the store' strategy. Then maybe a minimal nvim config (no plugins) + a medium config (with basic plugins).
# May need to try PlugSnapshot and install plugins as part of the derivation build...
#
# Same for zsh (not sure how it would work with plugins too)
#
# A Nix set that describe where each file should go

{}
