" This file configures neovim-qt's GUI layer, it is loaded when the Gui is
" initialized.
" it should be saved to C:\Users\YOUR_NAME\AppData\Local\nvim\ginit.vim
" vim:set ff=dos:

" To avoid spreading the config everywhere, the main init.vim configures
" the Gui layer by executing actions on the following autocmd:
doautocmd User GuiInitialized
