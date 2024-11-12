# My Git config

The config is separated in multiple topic files.

The idea is that every time I want my config, I'll want the general common configs + custom stuff.

To get started, `cp ./config.example ./config` and edit it with the relevant configs for your
directories and user(s) setup.


### Notes

**Why common are in dedicated dir instead of plainly in git folder?**
To be able to symlink the whole common dir, without the actual config entrypoint that is going to be
specific and shouldn't be common.
