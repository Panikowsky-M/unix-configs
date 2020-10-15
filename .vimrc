set number
syntax enable
set runtimepath+=~/.vim
set encoding=utf-8

autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

call plug#begin()
    Plug'dracula/vim',{'as':'dracula'}
    Plug'scrooloose/nerdtree',{'as':'nerdtree'}
    Plug'ycm-core/YouCompleteMe',{'as':'ycm'}
    Plug'skammer/vim-css-color',{'as':'css-color'}
call plug#end()
