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
    on_colors = function(c)
        -- Make status line less pronounced
        c.bg_status_line_active = c.bg_dim
        c.bg_status_line_inactive = c.bg_dim
    end,
    on_highlights = function(h, c)
        h.LineNr = { fg = c.fg_dim, bg = c.bg_main }
        h.LineNrAbove = { fg = c.fg_dim, bg = c.bg_main }
        h.LineNrBelow = { fg = c.fg_dim, bg = c.bg_main }
        h.WhichKeyFloat = { bg = c.bg_dim }

        -- Actually highlight changed text within a changed line
        -- FIXME: Not enough contrast
        h.DiffText = { fg = c.fg_changed, bg = c.bg_changed_refine }

        -- Don't highlight background of git gutter
        h.GitSignsAdd = { fg = c.fg_added }
        h.GitSignsChange = { fg = c.fg_changed }
        h.GitSignsDelete = { fg = c.fg_removed }
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

" Use custom mappings for vim-tmux-navigator
let g:tmux_navigator_no_mappings = 0
nnoremap <silent> <M-h> :<C-U>TmuxNavigateLeft<cr>
nnoremap <silent> <M-j> :<C-U>TmuxNavigateDown<cr>
nnoremap <silent> <M-k> :<C-U>TmuxNavigateUp<cr>
nnoremap <silent> <M-l> :<C-U>TmuxNavigateRight<cr>

" By default timeoutlen is 1000 ms
set timeoutlen=250

lua << END
local function diff_source()
    local gitsigns = vim.b.gitsigns_status_dict
    if gitsigns then
        return {
            added = gitsigns.added,
            modified = gitsigns.changed,
            removed = gitsigns.removed
        }
    end
end

require("lualine").setup {
    options = {
        icons_enabled = false,
        section_separators = '',
        component_separators = '|',
    },
    sections = {
        lualine_b = {
            'b:gitsigns_head',
            {'diff', source = diff_source},
            'diagnostics',
        },
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

require("fzf-lua").setup {
    winopts = {
        preview = {
            layout = "vertical",
            vertical = "up:55%",
        },
    },
}

require("which-key").register({
    ["<leader>"] = {
        [" "] = { "<cmd>FzfLua<cr>", "FzfLua" },
        ["/"] = { "<cmd>FzfLua live_grep_glob<cr>", "Grep" },
        ["?"] = { "<cmd>FzfLua live_grep_glob resume=true<cr>", "Grep (resume)" },
        ["*"] = {
            function()
                local fzf = require("fzf-lua")
                local opts = {
                    no_esc = true,
                    search = [[\b]] .. fzf.utils.rg_escape(vim.fn.expand("<cword>")) .. [[\b]],
                }
                fzf.live_grep_glob(opts)
            end,
            "Grep cword"
        },
        f = { "<cmd>FzfLua files<cr>", "Files" },
        F = { "<cmd>FzfLua files resume=true<cr>", "Files (resume)" },
        t = {
            name = "Tags",
            s = { "<cmd>FzfLua tagstack<cr>", "Stack" },
            w = { "<cmd>FzfLua tags_grep_cword<cr>", "Grep cword" },
            W = { "<cmd>FzfLua tags_grep_cWORD<cr>", "Grep cWORD" },
            ["/"] = { "<cmd>FzfLua tags_live_grep<cr>", "Grep" },
        },
        b = { "<cmd>FzfLua buffers<cr>", "Buffers" },
        j = { "<cmd>FzfLua jumps<cr>", "Jumps" },
        g = {
            name = "Git",
            n = { "<cmd>Gitsigns next_hunk<cr>", "Next hunk" },
            p = { "<cmd>Gitsigns prev_hunk<cr>", "Prev hunk" },
            a = { "<cmd>Gitsigns stage_hunk<cr>", "Stage hunk" },
            r = { "<cmd>Gitsigns reset_hunk<cr>", "Reset hunk" },
            u = { "<cmd>Gitsigns undo_stage_hunk<cr>", "Undo stage hunk" },
            v = { "<cmd>Gitsigns preview_hunk<cr>", "Preview hunk" },
            b = { "<cmd>Gitsigns blame_line<cr>", "Blame line" },
            B = { "<cmd>Gitsigns toggle_current_line_blame<cr>", "Toggle current line blame" },
            s = { "<cmd>FzfLua git_status<cr>", "Status" },
            l = { "<cmd>FzfLua git_bcommits<cr>", "Log (current file)" },
            L = { "<cmd>FzfLua git_commits<cr>", "Log" },
        },
        d = {
            name = "Diagnostics",
            v = { "<cmd>lua vim.diagnostic.open_float()<cr>", "View float" },
            s = { "<cmd>FzfLua diagnostics_document<cr>", "Show in file" },
            w = { "<cmd>FzfLua diagnostics_workspace<cr>", "Show in workspace" },
            d = { "<cmd>lua vim.diagnostic.disable()<cr>", "Disable" },
            e = { "<cmd>lua vim.diagnostic.enable()<cr>", "Enable" },
        },
        l = {
            name = "Language Server",
            s = { "<cmd>LspStart<cr>", "Start Language Server" },
            k = { "<cmd>LspStop<cr>", "Stop Language Server" },
        },
    },
    ["["] = {
        d = { "<cmd>lua vim.diagnostic.goto_prev()<cr>", "Previous diagnostic" },
        e = { "<cmd>lua vim.diagnostic.goto_prev{severity = 'error'}<cr>", "Previous error" },
        g = { "<cmd>Gitsigns prev_hunk<cr>", "Previous git hunk" },
    },
    ["]"] = {
        d = { "<cmd>lua vim.diagnostic.goto_next()<cr>", "Next diagnostic" },
        e = { "<cmd>lua vim.diagnostic.goto_next{severity = 'error'}<cr>", "Next error" },
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
