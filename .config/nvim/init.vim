" force cursor to stay in the middle line when possible
set so=999
" disable mouse
set mouse=

" File behaviour "

set expandtab
set shiftwidth=4
set tabstop=4

" Plugins "

set loadplugins

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
        -- Make status line less pronounced
        colors.bg_status_line_active = colors.bg_dim
    end,
    on_highlights = function(highlights, colors)
        highlights.LineNr = { fg = colors.fg_dim, bg = colors.bg_main }
        highlights.WhichKeyFloat = { bg = colors.bg_dim }
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

nnoremap <leader><Space> <cmd>FzfLua<cr>
nnoremap <leader>/ <cmd>FzfLua live_grep_glob<cr>
nnoremap <leader>f <cmd>FzfLua files<cr>
nnoremap <leader>t <cmd>FzfLua tagstack<cr>
nnoremap <leader>b <cmd>FzfLua buffers<cr>
nnoremap <leader>j <cmd>FzfLua jumps<cr>
nnoremap <leader>gn <cmd>Gitsigns next_hunk<cr>
nnoremap <leader>gp <cmd>Gitsigns prev_hunk<cr>
nnoremap <leader>ga <cmd>Gitsigns stage_hunk<cr>
nnoremap <leader>gu <cmd>Gitsigns undo_stage_hunk<cr>
nnoremap <leader>gv <cmd>Gitsigns preview_hunk<cr>
nnoremap <leader>gb <cmd>Gitsigns blame_line<cr>

lua << END
require("lualine").setup {
    options = {
        icons_enabled = false,
        section_separators = '',
        component_separators = '|',
    },
    sections = {
        lualine_x = {'encoding', 'fileformat'},
    },
}

require("nvim-treesitter.configs").setup {
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
        "yaml",
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
