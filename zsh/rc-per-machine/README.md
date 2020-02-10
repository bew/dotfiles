Make a directory for each machine, then put your files there.

E.g:

```
/per-machine/
- some-computer/
  - zshrc
  - zshenv
```

To make them effective on the wanted machine, you can load the additional files by symlinking them to `~/.zshrc.local` and `~/.zshenv.local`.
