Like my other tools, I want to be able to install my config in an editable way (for my dev machine)
and in a static way with Nix only, to make `nix run github:bew/cli#some-nvim-preset` (or similar)
work, without touching any of the standard config/data files on user's host.

Editable install is easy, basically: just put some symlinks and you're good to go.
Static & isolated config can be a tricky, as we need to find the right incantation and config setup
to not make it look at normal config if it exists.. AND make sure existing state & data isn't
overwritten by our setup.

---

In nvim 0.9+ we'll be able to use `$NVIM_APPNAME` (see: https://github.com/neovim/neovim/issues/21691),
to make fully separate 'profiles' of nvim configs.
It allows to have a different name than `nvim` in all standard searched locations.
So a start with `NVIM_APPNAME=my-foobar` would try to load `$XDG_CONFIG_HOME/my-foobar/init.lua`.

In addition, it should already possible to load initial `init.{vim,lua}` if the normal / standard one
isn't found:
From `:h VIMINIT`:
> ```
> b. Locations searched for initializations, in order of preference:
>    -  $VIMINIT environment variable (Ex command line).
>    -  User |config|: $XDG_CONFIG_HOME/nvim/init.vim (or init.lua).
>    -  Other config: {dir}/nvim/init.vim (or init.lua) where {dir} is any
>       directory in $XDG_CONFIG_DIRS.
>    -  $EXINIT environment variable (Ex command line).
>    |$MYVIMRC| is set to the first valid location unless it was already
>    set or when using $VIMINIT.
> ```

The important item being:
> ```
> Other config: {dir}/nvim/init.vim (or init.lua) where {dir} is any
> directory in $XDG_CONFIG_DIRS.
> ```

On that last point, I actually tested it, and can't make it work for now :/
> I don't have a standard init.lua in `$XDG_CONFIG_HOME`, I created a simple `/tmp/test-nvim-xdg-dirs/nvim/init.lua` file with a print and I'm starting nvim with: `XDG_CONFIG_DIRS=/tmp/test-nvim-xdg-dirs nvim`.
> But it's not working. If I then do a `runtime! init.lua` it gets loaded so the env var is well set, any idea why this is?
> (Currently using nvim 0.8.2)

---

For Nix pkging we can combine both, with a complex `$NVIM_APPNAME` & custom `$XDG_CONFIG_DIRS`:
```sh
NVIM_APPNAME="xxxxxxxxsomebighashxxxxxxx-some-nvim-preset"
XDG_CONFIG_DIRS="/tmp/test-nvim-xdg-dirs:$XDG_CONFIG_DIRS"

# with folders
/tmp/test-nvim-xdg-dirs/$NVIM_APPNAME/
+ lua/... # (config)
+ init.lua
```
The complex (non-standard) `$NVIM_APPNAME`, ensures the config won't be found & loaded in the standard locations,
and I won't be reading user's usual config / overwriting user's usual state/runtime files.
Specifying the `$XDG_CONFIG_DIRS` allows to put the config anywhere, outside of `$XDG_CONFIG_HOME`.
