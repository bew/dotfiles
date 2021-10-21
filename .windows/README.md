# Windows-only configs

All these programs can be installed without administrative rights.

## Windows Desktop Environment - Various utils

### AutoHotKey : remap all the things!

https://www.autohotkey.com/

The _ultimate_ tool to remap keys, create new shortcuts globally and specific windows, ...
All my non-terminal shortcuts are defined as AutoHotKey scripts in `autohotkey-scripts/`


### AltDrag : Win + click to move / resize windows

**Original project**:
https://stefansundin.github.io/altdrag/
https://github.com/stefansundin/altdrag

**Maintained fork**:
https://github.com/RamonUnch/AltSnap
(disabled buggy features, fixes many bugs and undesired behavior, and adds nice things like transparent windows dragging, maximize action (during drag), ..)

It has many other nice utilities with Alt/Ctrl/Shift + mouse clicks on the windows


## Editor - Neovim

https://neovim.io/
I use the nvim-qt variant on windows, for basic file opening, text processing, basic editing is
also possible as I installed a basic neovim config for nvim-qt (see in ./nvim-config)


## Terminal - WezTerm :heart: :heart: :heart:

https://wezfurlong.org/wezterm/
https://github.com/wez/wezterm

A GPU-accelerated cross-platform terminal emulator and multiplexer written by @wez and implemented in Rust.

**The Best Terminal Emulator**, with advanced config possibilities using Lua.

- Mouse fully working when doing ssh
- Custom font loading from a folder (not from Windows), I can use the font I want
- Full emoji support, unicode chars, normal/bold/italic/underline
- Ligature support (:heart:)
- Full key/mouse bindings configuration (with custom events if I want)
- Written in Rust (:heart: And I made a few contributions!)
- Lots of escape sequence support (Image display, Clipboard, Notifications)
- Lua for config file, many builtin functions, lots of config options
- Hyperlink support (but I don't use it currently)
- Wez is a very friendly dev, HE HAS A SHIT-TON OF KNOWLEDGE, and he accepts my PRs (:


## Local Linux-like shell - MSYS2

https://www.msys2.org/

Local install of a 'pacman' variant for Windows, with a generous set of packages that work on Windows natively.

I can install git, neovim (cli version) and have a proper CLI experience
(didn't try to install zsh, my config probably ONLY works on Linux)
