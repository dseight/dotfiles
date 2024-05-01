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
set completeopt-=preview " don't show preview *window* (not float) on completion

" Bindings "

" Use space as <leader> key
nnoremap <SPACE> <Nop>
let mapleader=" "
let g:mapleader = "\<Space>"

" By default timeoutlen is 1000 ms
set timeoutlen=250

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
        "python",
        "cpp",
        "fish",
        "json",
        "devicetree",
        "make",
        "markdown",
        "qmljs",
        "rust",
        "toml",
        "lua",
        "vim",
        "vimdoc",
    },
    sync_install = false,
    highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
    },
    indent = {
        enable = true,
        disable = {
            "python",
        },
    },
}

require("which-key").register({
    ["<leader>"] = {
        [" "] = { "<cmd>FzfLua<cr>", "FzfLua" },
        ["/"] = { "<cmd>FzfLua live_grep_glob<cr>", "Grep" },
        f = { "<cmd>FzfLua files<cr>", "Files" },
        t = { "<cmd>FzfLua tagstack<cr>", "Tag stack" },
        b = { "<cmd>FzfLua buffers<cr>", "Buffers" },
        j = { "<cmd>FzfLua jumps<cr>", "Jumps" },
        g = {
            name = "Git",
            n = { "<cmd>Gitsigns next_hunk<cr>", "Next hunk" },
            p = { "<cmd>Gitsigns prev_hunk<cr>", "Prev hunk" },
            a = { "<cmd>Gitsigns stage_hunk<cr>", "Stage hunk" },
            u = { "<cmd>Gitsigns undo_stage_hunk<cr>", "Undo stage hunk" },
            v = { "<cmd>Gitsigns preview_hunk<cr>", "Preview hunk" },
            b = { "<cmd>Gitsigns blame_line<cr>", "Blame line" },
            s = { "<cmd>FzfLua git_status<cr>", "Status" },
        },
        d = {
            name = "Diagnostics",
            v = { "<cmd>lua vim.diagnostic.open_float()<cr>", "View float" },
            s = { "<cmd>FzfLua diagnostics_document<cr>", "Show in file" },
            w = { "<cmd>FzfLua diagnostics_workspace<cr>", "Show in workspace" },
        },
        l = {
            name = "Language Server",
            s = { "<cmd>LspStart<cr>", "Start Language Server" },
            k = { "<cmd>LspStop<cr>", "Stop Language Server" },
        },
    },
    ["["] = {
        d = { "<cmd>lua vim.diagnostic.goto_prev()<cr>", "Previous diagnostic" },
        g = { "<cmd>Gitsigns prev_hunk<cr>", "Previous git hunk" },
    },
    ["]"] = {
        d = { "<cmd>lua vim.diagnostic.goto_next()<cr>", "Next diagnostic" },
        g = { "<cmd>Gitsigns next_hunk<cr>", "Next git hunk" },
    },
})

require("gitsigns").setup {
    signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "-" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
    },
}

require("lint").linters_by_ft = {
    fish = { "fish" },
    python = { "mypy" },
    sh = { "shellcheck" },
}

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
    callback = function()
        -- Run linters defined in `linters_by_ft`
        require("lint").try_lint()
        -- Always run typos linter
        require("lint").try_lint("typos")
    end,
})

local lspconfig = require("lspconfig")
lspconfig.clangd.setup {
    autostart = false,
}
lspconfig.ruff_lsp.setup {
    cmd = { "python3", "-m", "ruff", "server", "--preview" },
}
END
