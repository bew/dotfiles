# bew's dotfiles :)

My personal dotfiles.

Don't clone and run this as is, but feel free to take a look and steal parts/ideas.

Open an issue if you have any questions, happy to help.

---

## Installation

```sh
# Clone the repository
git clone git@github.com:bew/dotfiles.git ~/.config/dotfiles

# Install all the symlinks
~/.config/dotfiles/install_bruteforce.zsh --dry-run
```

Check READMEs in nvim/ & zsh/

## git lfs

Some big binaries are tracked using git-lfs, you'll need to install it in your environment, then ask it to install itself in your project's git config with:
```
git lfs install --local
```
