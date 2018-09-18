Make a directory for each machine, then put your files there.

E.g:

```
/per-machine/
- cheerz-hp/
  - zshrc
  - zshenv
```

To make them effective on the wanted machine, you can load the additional files by (sym-)linking them to `~/.zshrc.local` and `~/.zshenv.local`.
