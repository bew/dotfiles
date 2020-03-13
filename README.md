# bew's dotfiles :)

## Installation

```sh
# Clone the repository
git clone git@github.com:bew/dotfiles.git ~/.config/dotfiles

# Install all the symlinks (maybe one day I'll allow to install only part of them)
~/.config/dotfiles/install_bruteforce.zsh --dry-run
```


## GUI config

### caps2esc for Caps to Escape/Ctrl (when held)

> Author project: https://github.com/oblitum/caps2esc
> (forked under my account for posterity)

yay -S caps2esc
sudo systemctl enable caps2esc.service
sudo systemctl start caps2esc.service
