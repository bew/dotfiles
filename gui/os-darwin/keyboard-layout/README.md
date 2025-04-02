# Custom keyboard layout ✨🚀


## My layout

The `./French-PC.actually-sane.keylayout` layout is a heavily modified `French - PC` layout:

- Adds many comments in the layout spec file

- Changes ALT keymap: no weird symbols when doing ALT+letter like `Ò` with `Alt+s` 🤬, we now get proper ALT+letter in applications.

  It's not a perfect impl though, as I still need RightALT + number row to give symbols, and since
  trying to have different keymaps for left / right ALT keys, both ALT + number row gives symbols.

- Removes any keymaps using CAPS


## Install a keyboard layout

```sh
$ ln -s ~/.dot/full/path/to/something.keylayout /Library/Keyboard Layouts/
```

Then open dialog to add a new Input Source, in `System Preferences > Keyboard > Input Sources`,
navigate in the 'Other' language and select the layout, then switch to that layout with the layout
switcher in the top bar.

> [!NOTE]
> If the custom keyboard layout does not appear in 'Other', try rebooting.

> [!WARNING]
> GRR: After adding a 2nd input sources (going from 1 to 2+ sources), the default keyboard shortcut
> to switch to next input source (`Ctrl-Space`) is RE-ENABLED by force, even if it was manually
> disabled before 🤬..
>
> 👉 Need to go in `System Preferences > Keyboard > Keyboard shortcuts`, section `Input Sources`
> and disable both shortcuts.


## Update the keyboard layout

Once the computer is started or once the input source is registered, the source `.keylayout` file
can be changed/deleted, the input source won't break.

To update the keyboard layout, it seems that I need to restart the computer 🤷.


---

TODO: Understand what all the `&#x0009;` & similar values in key's `output` are exactly 🤔

TODO: Have a mapping of key code to key name (in a standard FR-layout)

MAYBE: show the virtual key code + un-garbled output meaning in neovim after-line-virtual-text?


## What is this, file format, how to preview

MacOS supports 2 ways to install keyboard layouts:
- a `something.keylayout` file
- a `something.bundle` file


### `.keylayout` File Format:

Official spec:
<https://developer.apple.com/library/archive/technotes/tn2056/_index.html>

Another, simpler doc:
<https://gist.github.com/lancejpollard/b2377a181b5049654abe140cd843b84c>


### Ukulele, a GUI editor/preview

> [!TIP]
> Even though the raw file (with some comments) and the official spec makes the file quite easy to
> read, having a way to visualize everything can always be useful!

https://software.sil.org/ukelele/

(Sets itself as the default app for `.keylayout` files)

> [!WARNING]
> Editing a `.keylayout` file in Ukulele removes some manually-written comments 😖


## NOTES: Limitation of MacOS layouts

- No way to set a modifier+key to output othermodifier+otherkey

- Differentiating left vs right ALT modifiers (`option` vs `rightOption` in kyylayout file) doesn't
  seem to work..

  Same issue as: <https://apple.stackexchange.com/q/431564/591273>

  👉 To work around this, the ALT keymap has nothing for letters, and ONLY has symbols when used
  with the number row.
