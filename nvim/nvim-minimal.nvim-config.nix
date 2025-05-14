{ config, pkgs, ... }:

let
  cfg = config;
in {
  _class = "tool.nvim"; # type of nix module

  ID = "nvim-minimal";
  package = pkgs.neovim.override {
    withPython3 = false;
    withRuby = false;
  };

  nvimDir."init.vim".text = /* vim */ ''
    set shiftwidth=2 expandtab
    set mouse=nv
    set iskeyword+=-
    set ignorecase smartcase
    set smartindent
    set number relativenumber
    set cursorline
    " mappings
    nnoremap Y yy
    nnoremap <M-s> :w<cr>
    inoremap <M-s> <esc>:w<cr>
    nnoremap § :nohl<cr>
    nnoremap <M-a> gT
    nnoremap <M-z> gt
    nnoremap Q :q<cr>
    " logical redo
    nnoremap U <C-r>
    " window navigation
    nnoremap <C-h> <C-w>h
    nnoremap <C-j> <C-w>j
    nnoremap <C-k> <C-w>k
    nnoremap <C-l> <C-w>l
    " basic cmdline navigation
    cnoremap <M-k> <Up>
    cnoremap <M-j> <Down>
    " colorscheme (NOTE: need my colorscheme in nvimDir!)
    colorscheme bew256-dark
  '';
  nvimDir."colors/bew256-dark.vim".source = ./colors/bew256-dark.vim;

  nvimDir."plugin/foo.lua".text = /* lua */ ''
    vim.notify "hello from config! (ID: ${cfg.ID})"
  '';
}
