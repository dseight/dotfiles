set noerrorbells

" force cursor to stay in the middle line when possible
set so=999
" disable mouse
set mouse=
set wildmenu

" Appearance "

syntax enable

set number
set relativenumber

set noshowmode
set laststatus=2

set background=dark
hi LineNr ctermfg=gray
hi VertSplit cterm=NONE ctermfg=darkgray ctermbg=NONE

if !has('gui_running')
    set t_Co=256
endif

" Search "

set smartcase
set hlsearch
set incsearch

" File behaviour "

set expandtab
set smarttab
set nostartofline

set shiftwidth=4
set tabstop=4

" Bindings "

set backspace=indent,eol,start

" Use space as <leader> key
nnoremap <SPACE> <Nop>
let mapleader=" "

" Plugins "

" Install and run vim-plug on first run
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
    silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Prevent sleuth.vim from slowing down the startup time
let g:polyglot_disabled = ['autoindent']

call plug#begin(data_dir . '/plugged')

Plug 'airblade/vim-gitgutter', { 'commit': '67ef116100b40f9ca128196504a2e0bc0a2753b0' }
Plug 'ntpeters/vim-better-whitespace', { 'commit': '029f35c783f1b504f9be086b9ea757a36059c846' }
Plug 'itchyny/lightline.vim', { 'commit': '58c97bc21c6f657d3babdd4eefce7593e30e75ce' }
Plug 'itchyny/vim-gitbranch', { 'commit': '1a8ba866f3eaf0194783b9f8573339d6ede8f1ed' }
Plug 'sheerun/vim-polyglot', { 'commit': 'bc8a81d3592dab86334f27d1d43c080ebf680d42' }
if v:version >= 800
    " NOTE: fzf binary must be installed separately
    Plug 'junegunn/fzf.vim', { 'commit': '45d96c9cb1213204479593236dfabf911ff15443' }
endif

call plug#end()

" Match color of gitgutter with line numbers background
highlight! link SignColumn LineNr

highlight GitGutterAdd ctermfg=green ctermbg=NONE
highlight GitGutterChange ctermfg=yellow ctermbg=NONE
highlight GitGutterDelete ctermfg=red ctermbg=NONE
highlight GitGutterChangeDelete ctermfg=yellow ctermbg=NONE

let g:lightline = {
  \     'colorscheme': 'one',
  \     'active': {
  \         'left': [['mode', 'paste' ], ['readonly', 'filename', 'modified']],
  \         'right': [['lineinfo'], ['percent'], ['gitbranch', 'fileformat', 'fileencoding']]
  \     },
  \     'component_function': {
  \         'gitbranch': 'gitbranch#name'
  \     }
  \ }
