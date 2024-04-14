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

" Prevent sleuth.vim from slowing down the startup time
let g:polyglot_disabled = ['autoindent']

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
