## GUI config

Configs for all GUI pograms are here.

**used**:

- herbstluftwm
- polybar
- tridactyl
- urxvt
- wezterm
- xinitrc
- xprofile
- Xresources
- Xresources.d

**not used**:

- alacritty
- kitty
- picom.config
- xkbmap.config

---

**caps2esc for Caps to Escape/Ctrl (when held)**:

> Author project: https://github.com/oblitum/caps2esc
> (forked under my account for posterity)

```
yay -S caps2esc
sudo systemctl enable caps2esc.service
sudo systemctl start caps2esc.service
```

TODO: use [interception tools](https://gitlab.com/interception/linux/tools) with its caps2esc 'plugin'
