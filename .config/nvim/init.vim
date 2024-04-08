" force cursor to stay in the middle line when possible
set so=999
" disable mouse
set mouse=

" File behaviour "

set expandtab
set shiftwidth=4
set tabstop=4

" Plugins "

" Install and run vim-plug on first run
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
    silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin(data_dir . '/plugged')

Plug 'lewis6991/gitsigns.nvim', { 'commit': '6ef8c54fb526bf3a0bc4efb0b2fe8e6d9a7daed2' }
Plug 'ntpeters/vim-better-whitespace', { 'commit': '029f35c783f1b504f9be086b9ea757a36059c846' }
Plug 'nvim-lualine/lualine.nvim', { 'commit': '0a5a66803c7407767b799067986b4dc3036e1983' }
Plug 'nvim-treesitter/nvim-treesitter', { 'commit': 'a2d6678bb21052013d0dd7cb35dffbac13846c98', 'do': ':TSUpdate' }
" NOTE: fzf binary must be installed separately
Plug 'ibhagwan/fzf-lua', { 'commit': '97a88bb8b0785086d03e08a7f98f83998e0e1f8a', 'branch': 'main' }
Plug 'folke/which-key.nvim', { 'commit': '4433e5ec9a507e5097571ed55c02ea9658fb268a' }
Plug 'miikanissi/modus-themes.nvim', { 'commit': '7cef53b10b6964a0be483fa27a3d66069cefaa6c' }

call plug#end()

" Appearance "

set termguicolors

lua << END
require("modus-themes").setup({
    on_colors = function(colors)
        -- Don't highlight background of git gutter. This also affects
        -- :Gitsigns preview_hunk, thus bg is set to none instead of bg_main
        colors.bg_added = colors.none
        colors.bg_changed = colors.none
        colors.bg_removed = colors.none
    end,
    on_highlights = function(highlights, colors)
        highlights.LineNr = { fg = colors.fg_dim, bg = colors.bg_main }
    end,
})
END

colorscheme modus
set number
set relativenumber
set listchars=tab:>\ ,trail:·,nbsp:~
set list
set noshowmode " provided by lightline

" Bindings "

" Use space as <leader> key
nnoremap <SPACE> <Nop>
let mapleader=" "
let g:mapleader = "\<Space>"

" By default timeoutlen is 1000 ms
set timeoutlen=250

" FzfLua bindings
nnoremap <leader><Space> <cmd>FzfLua<cr>
nnoremap <leader>b <cmd>FzfLua buffers<cr>
nnoremap <leader>f <cmd>FzfLua files<cr>
nnoremap <leader>g <cmd>FzfLua live_grep_glob<cr>
nnoremap <leader>c <cmd>FzfLua commands<cr>
nnoremap <leader>j <cmd>FzfLua jumps<cr>

lua << END
require'lualine'.setup {
    options = {
        icons_enabled = false,
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

require("which-key").setup {}

require("gitsigns").setup {
    signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "-" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
    },
}
END
