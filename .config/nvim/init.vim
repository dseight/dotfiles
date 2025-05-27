" force cursor to stay in the middle line when possible
set so=999
" disable mouse
set mouse=

" File behaviour "

set expandtab
set shiftwidth=4
set tabstop=4
" Wrap git commit messages
autocmd bufreadpre COMMIT_EDITMSG setlocal textwidth=72

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
        h.CursorLineNetrw = { fg = c.none, bg = c.bg_hl_line }
        h.WhichKeyFloat = { bg = c.bg_dim }

        -- Actually highlight changed text within a changed line
        h.DiffText = { fg = c.fg_changed, bg = c.bg_changed_refine }
        -- Don't use too intense highlight for the changed lines.
        -- This is needed for diffing logs, where a lot of changes
        -- are just timestamp changes.
        h.DiffChange = { fg = c.fg_changed, bg = c.bg_changed_faint }
        -- Adjust the rest of the colors to be less intense.
        h.DiffAdd = { fg = c.fg_added, bg = c.bg_added_faint }
        h.DiffDelete = { fg = c.fg_removed, bg = c.bg_removed_faint }

        -- Make listchars just a tiny bit less distractive.
        -- FIXME: This don't play well with visual selection.
        h.Whitespace = { fg = c.border }

        -- Don't highlight background of git gutter
        h.GitSignsAdd = { fg = c.fg_added }
        h.GitSignsChange = { fg = c.fg_changed }
        h.GitSignsDelete = { fg = c.fg_removed }
    end,
})
END

colorscheme modus
set number
set cursorline
set listchars=tab:>\ ,trail:·,nbsp:~
set list
set noshowmode " provided by lightline
set completeopt-=preview " don't show preview *window* (not float) on completion

augroup CursorLineOnlyInNetrw
    autocmd!
    autocmd BufEnter * hi! CursorLine NONE
    " Handle normal buffer switch scenarios
    autocmd FileType netrw hi! link CursorLine CursorLineNetrw
    " Handle weird scenarios like calling ":FzfLua lsp_finder"
    " while being in netrw
    autocmd BufEnter * if &filetype == 'netrw'
        \ | hi! link CursorLine CursorLineNetrw
        \ | endif
augroup END

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

local function diagnostic_enable(enable, ns_name)
    local ns = vim.api.nvim_get_namespaces()[ns_name]
    if ns ~= nil then
        vim.diagnostic.enable(enable, {ns_id = ns})
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
            d = { "<cmd>Gitsigns diffthis<cr>", "Diff" },
            D = { "<cmd>Gitsigns diffthis HEAD~<cr>", "Diff (prev commit)" },
            s = { "<cmd>FzfLua git_status<cr>", "Status" },
            l = { "<cmd>FzfLua git_bcommits<cr>", "Log (current file)" },
            L = { "<cmd>FzfLua git_commits<cr>", "Log" },
        },
        d = {
            name = "Diagnostics",
            v = { "<cmd>lua vim.diagnostic.open_float()<cr>", "View float" },
            s = { "<cmd>FzfLua diagnostics_document<cr>", "Show in file" },
            w = { "<cmd>FzfLua diagnostics_workspace<cr>", "Show in workspace" },
            d = {
                name = "Disable",
                a = { vim.diagnostic.disable, "All" },
                t = { function() diagnostic_enable(false, "typos") end, "Typos" },
                c = { function() diagnostic_enable(false, "checkpatch") end, "checkpatch.pl" },
            },
            e = {
                name = "Enable",
                a = { vim.diagnostic.enable, "All" },
                t = { function() diagnostic_enable(true, "typos") end, "Typos" },
                c = { function() diagnostic_enable(true, "checkpatch") end, "checkpatch.pl" },
            },
        },
        l = {
            name = "Language Server",
            l = { "<cmd>LspStart<cr>", "Start Language Server" },
            L = { "<cmd>LspStop<cr>", "Stop Language Server" },
            K = { vim.lsp.buf.hover, "Show Hover (use just K!)" },
            R = { vim.lsp.buf.rename, "Rename" },
            r = { "<cmd>FzfLua lsp_references<cr>", "References" },
            i = { "<cmd>FzfLua lsp_incoming_calls<cr>", "Incoming calls" },
            d = { "<cmd>FzfLua lsp_declarations<cr>", "Declarations" },
            D = { "<cmd>FzfLua lsp_definitions<cr>", "Definitions" },
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
    cmd = { "clangd", "--clang-tidy" },
}
lspconfig.ruff_lsp.setup {
    cmd = { "ruff", "server", "--preview" },
}
END
