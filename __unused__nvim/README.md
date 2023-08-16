# Neovim config

## Bootstrap

1. Create python venv:

   ```sh
   ./make-py-venv-for-nvim ./py-venv-requirements.txt
   ```
   (if it already exists, you can re-create it with `--force`)

2. Install plugins:

   ```sh
   nvim +PlugInstall +q
   ```

3. Start nvim! You might need to update remote plugins with `:UpdateRemotePlugins` (you'd get a message telling you to do so if needed)
