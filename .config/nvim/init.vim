" force cursor to stay in the middle line when possible
set so=999

" Appearance "

set number
set relativenumber

" Mode is provided by lightline, so disable built-in mode display
set noshowmode

hi LineNr ctermfg=gray
hi VertSplit cterm=NONE ctermfg=darkgray ctermbg=NONE

if !has('gui_running')
    set t_Co=256
endif

" File behaviour "

set expandtab

set shiftwidth=4
set tabstop=4

" Bindings "

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

call plug#begin(data_dir . '/plugged')

Plug 'airblade/vim-gitgutter'
Plug 'ntpeters/vim-better-whitespace'
Plug 'nvim-lualine/lualine.nvim'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'tmux-plugins/vim-tmux'
Plug 'ackyshake/VimCompletesMe'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

call plug#end()

" Match color of gitgutter with line numbers background
highlight! link SignColumn LineNr

highlight GitGutterAdd ctermfg=green ctermbg=NONE
highlight GitGutterChange ctermfg=yellow ctermbg=NONE
highlight GitGutterDelete ctermfg=red ctermbg=NONE
highlight GitGutterChangeDelete ctermfg=yellow ctermbg=NONE

lua << END
require'lualine'.setup {
    options = {
        icons_enabled = false,
        theme = 'iceberg_dark',
        section_separators = '',
        component_separators = '|',
    },
    sections = {
        lualine_x = {'encoding', 'fileformat'},
    }
}

require'nvim-treesitter.configs'.setup {
    ensure_installed = {
        "bash",
        "c",
        "cmake",
        "cpp",
        "fish",
        "json",
        "make",
        "markdown",
        "qmljs",
        "rust",
        "toml",
        "typescript",
        "vala",
        "vim",
        "yaml"
    },
    sync_install = false,
    highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
    },
}
END
