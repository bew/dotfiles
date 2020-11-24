# bew's dotfiles :)

## Installation

```sh
# Clone the repository
git clone git@github.com:bew/dotfiles.git ~/.config/dotfiles

# Install all the symlinks (maybe one day I'll allow to install only part of them)
~/.config/dotfiles/install_bruteforce.zsh --dry-run
```

## git lfs

Some big binaries are tracked using git-lfs, you'll need to install it in your environment, then ask it to install itself in your project's git config with:
```
git lfs install --local
```


## GUI config

### caps2esc for Caps to Escape/Ctrl (when held)

> Author project: https://github.com/oblitum/caps2esc
> (forked under my account for posterity)

```
yay -S caps2esc
sudo systemctl enable caps2esc.service
sudo systemctl start caps2esc.service
```
