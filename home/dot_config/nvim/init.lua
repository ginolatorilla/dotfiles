-- =====================================================================================
-- OPTIONS
-- =====================================================================================
vim.g.mapleader = ' '
vim.g.maplocaleader = ' '
vim.opt.termguicolors = true
vim.opt.relativenumber = true
vim.opt.list = true
vim.opt.listchars = { tab = '→ ', space = '·', extends = "❯", precedes = "❮" }

-- Editor (from VS Code settings + ~/.vimrc)
vim.opt.number = true
vim.opt.colorcolumn = { '80', '100', '120' } -- editor.rulers 79/99/119
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.expandtab = true
vim.opt.wrap = false
vim.opt.cursorline = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false
vim.opt.fixendofline = false -- vimrc: nofixeol
vim.opt.backup = false
vim.opt.signcolumn = 'yes'
vim.opt.diffopt:append({ 'linematch:60' }) -- closest to diffEditor.showMoves

local map = vim.keymap.set
local both = { 'n', 'i', 'v' }

-- Cmdline completion menu: arrows pick items while it is open, otherwise they browse history
map('c', '<down>', function() return vim.fn.wildmenumode() == 1 and '<c-n>' or '<down>' end, { expr = true })
map('c', '<up>', function() return vim.fn.wildmenumode() == 1 and '<c-p>' or '<up>' end, { expr = true })

-- Plugins that replace the VS Code Vim extension features
-- VS Code Cmd shortcuts. Ghostty sends Cmd+<key> as Alt+<key> (see config.ghostty).
map(both, '<M-s>', '<cmd>write<cr>', { desc = 'Cmd+S save' })
map('n', '<M-j>', '<leader>t', { remap = true, desc = 'Cmd+J terminal panel' })
map({ 'i', 'v' }, '<M-j>', '<esc><leader>t', { remap = true })
map('t', '<M-j>', [[<c-\><c-n><leader>t]], { remap = true })
map('n', '<M-/>', 'gcc', { remap = true, desc = 'Cmd+/ toggle comment' })
map('i', '<M-/>', '<esc>gcca', { remap = true })
map('v', '<M-/>', 'gc', { remap = true })

-- From ~/.vimrc
map('n', '<leader>s', '<cmd>split<cr>')
map('n', '<leader>v', '<cmd>vsplit<cr>')
map('n', '<leader>h', '<c-w>h')
map('n', '<leader>j', '<c-w>j')
map('n', '<leader>k', '<c-w>k')
map('n', '<leader>l', '<c-w>l')
map('n', '<leader><left>', '<c-w><left>')
map('n', '<leader><down>', '<c-w><down>')
map('n', '<leader><up>', '<c-w><up>')
map('n', '<leader><right>', '<c-w><right>')
map({ 'i', 'v' }, 'jk', '<esc>')
map({ 'i', 'v' }, 'kj', '<esc>')
map('v', '<', '<gv')
map('v', '>', '>gv')

-- =====================================================================================
-- PLUGINS
-- =====================================================================================
vim.pack.add({
  { src = "https://github.com/tpope/vim-surround" },
  { src = "https://github.com/wellle/targets.vim" }, -- vim.targets.enable
  { src = "https://github.com/kana/vim-textobj-user" },
  { src = "https://github.com/kana/vim-textobj-entire" },
  { src = "https://github.com/michaeljsmith/vim-indent-object" },
  { src = "https://github.com/chentoast/marks.nvim" },
}, { confirm = false })

local function addplugin(p)
  vim.pack.add({{ src = p }})
end

addplugin("https://github.com/bkad/CamelCaseMotion")
vim.g.camelcasemotion_key = '<leader>' -- vim.camelCaseMotion.enable (<leader>w/b/e)

addplugin("https://github.com/nvim-tree/nvim-web-devicons")
addplugin("https://github.com/nvim-tree/nvim-tree.lua")
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
require("nvim-tree").setup({
  sort = { sorter = "case_sensitive" },
  view = { width = 30 },
  renderer = { group_empty = true },
  filters = { dotfiles = false },
})

addplugin("https://github.com/akinsho/bufferline.nvim")
require('bufferline').setup {
  options = {
    -- mode = "tabs"
  }
}

addplugin("https://github.com/inkarkat/vim-ReplaceWithRegister")
-- disable LSP overlaps with replaceWithRegister
vim.keymap.del("n", "gra")
vim.keymap.del("n", "gri")

addplugin("https://github.com/nvim-treesitter/nvim-treesitter")
local lang = { 'bash', 'csv', 'diff', 'dockerfile', 'fish', 'git_config', 'git_rebase', 'gitattributes', 'gitcommit',
  'gitignore', 'go', 'gomod', 'gosum', 'gowork', 'gpg', 'groovy', 'helm', 'html', 'html_tags', 'http', 'ini', 'javascript',
  'jq', 'json', 'lua', 'make', 'markdown', 'markdown_inline', 'mermaid', 'nginx', 'passwd', 'promql', 'proto', 'python',
  'regex', 'rust', 'printf', 'requirements', 'scss', 'sql', 'ssh_config', 'starlark', 'terraform', 'toml', 'tsv', 'tsx',
  'typescript', 'yaml', }
require('nvim-treesitter').install(lang)
vim.api.nvim_create_autocmd('FileType', {
  pattern = lang,
  callback = function() pcall(vim.treesitter.start) end,
})
vim.filetype.add({
  pattern = {
    ["Jenkinsfile.*"] = "groovy",
    ["Dockerfile.*"] = "dockerfile",
    ["Makefile.*"] = "make",
  }
})

addplugin("https://github.com/olimorris/onedarkpro.nvim")
-- Follow the macOS appearance (the same signal Ghostty's light/dark theme follows). tmux does not relay live
-- terminal colour changes, so poll: on startup, on focus, and every 3s. Falls back to OSC 11 detection off macOS.
local function set_theme(dark)
  local bg = dark and 'dark' or 'light'
  if vim.o.background == bg and vim.g.colors_name == 'default' then return end
  vim.o.background = bg
  if dark then vim.cmd.colorscheme('onedark') else vim.cmd.colorscheme('onelight') end
end
local function sync_theme()
  if vim.fn.has('mac') == 0 then return end
  vim.system({ 'defaults', 'read', '-g', 'AppleInterfaceStyle' }, { text = true }, function(r)
    local dark = r.code == 0 and r.stdout:match('Dark') ~= nil
    vim.schedule(function() set_theme(dark) end)
  end)
end
if vim.fn.has('mac') == 1 then
  local out = vim.fn.system({ 'defaults', 'read', '-g', 'AppleInterfaceStyle' })
  set_theme(vim.v.shell_error == 0 and out:match('Dark') ~= nil)
else
  vim.cmd.colorscheme('default')
end
vim.api.nvim_create_autocmd({ 'FocusGained', 'VimResume' }, { callback = sync_theme })
vim.uv.new_timer():start(3000, 3000, vim.schedule_wrap(sync_theme))

addplugin("https://github.com/nvim-telescope/telescope.nvim")
addplugin("https://github.com/nvim-lua/plenary.nvim" )
addplugin("https://github.com/nvim-telescope/telescope-fzf-native.nvim")
local tb = function(fn, opts)
  return function() require('telescope.builtin')[fn](opts) end
end
require("telescope").load_extension("fzf")
map('n', '<leader>p', tb('find_files', { hidden = true }), { desc = 'Quick open' })
map('n', '<leader>;', tb('commands'), { desc = 'Command palette' })
map('n', '<leader>g', tb('live_grep'), { desc = 'Text search' })
map(both, '<M-p>', tb('find_files', { hidden = true }), { desc = 'Cmd+P quick open' })
map(both, '<M-P>', tb('commands'), { desc = 'Cmd+Shift+P command palette' })
map(both, '<M-F>', tb('live_grep'), { desc = 'Cmd+Shift+F search in files' })
-- Toggle, then reload + redraw next tick: the first open sometimes shows an empty tree until toggled again
local function toggle_tree()
  local api = require('nvim-tree.api')
  api.tree.toggle()
  vim.schedule(function()
    if api.tree.is_visible() then api.tree.reload() end
    vim.cmd.redraw({ bang = true })
  end)
end
map('n', '<leader>N', toggle_tree, { desc = 'File tree' })
map(both, '<M-b>', toggle_tree, { desc = 'Cmd+B sidebar' })

-- Terminal toggle / focus. The terminal buffer is kept hidden (shell stays alive) and re-shown.
local term_buf
local function term_win()
  if not (term_buf and vim.api.nvim_buf_is_valid(term_buf)) then return end
  local w = vim.fn.win_findbuf(term_buf)[1]
  return w
end
local function open_term()
  vim.cmd('botright 15split')
  if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
    vim.api.nvim_win_set_buf(0, term_buf)
  else
    vim.cmd.terminal()
    term_buf = vim.api.nvim_get_current_buf()
    vim.bo[term_buf].bufhidden = 'hide'
  end
  vim.cmd.startinsert()
end
map('n', '<leader>t', function()
  local w = term_win()
  if w then vim.api.nvim_win_hide(w) else open_term() end
end, { desc = 'Toggle terminal' })
map('n', '<leader>i', function()
  local w = term_win()
  if w then vim.api.nvim_set_current_win(w); vim.cmd.startinsert()
  else open_term() end
end, { desc = 'Focus terminal' })
map('t', '<esc><esc>', [[<c-\><c-n>]])

-- Build the node app after install/update. Must be registered before the plugin is added.
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    local d = ev.data
    if d.spec.name ~= 'markdown-preview.nvim' or not (d.kind == 'install' or d.kind == 'update') then return end
    if vim.fn.executable('npm') == 0 then
      vim.notify('markdown-preview.nvim: npm not found, build skipped', vim.log.levels.WARN)
      return
    end
    vim.system({ 'npm', 'install', '--no-audit', '--no-fund' }, { cwd = d.path .. '/app', text = true }, function(r)
      vim.schedule(function()
        if r.code == 0 then
          vim.notify('markdown-preview.nvim: build finished')
        else
          vim.notify('markdown-preview.nvim: build failed\n' .. (r.stderr or ''), vim.log.levels.ERROR)
        end
      end)
    end)
  end,
})
addplugin("https://github.com/iamcco/markdown-preview.nvim")
-- Cmd+Shift+V markdown preview (VS Code). Ghostty sends Cmd+Shift+V as Alt+Shift+V.
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  callback = function(ev)
    local o = { buffer = ev.buf, desc = 'Cmd+Shift+V markdown preview' }
    map('n', '<M-V>', '<cmd>MarkdownPreviewToggle<cr>', o)
    map({ 'i', 'v' }, '<M-V>', '<esc><cmd>MarkdownPreviewToggle<cr>', o)
    map('n', '<leader>mp', '<cmd>MarkdownPreviewToggle<cr>', o)
  end,
})

-- =====================================================================================
-- LSP (gopls, pylsp) + FORMATTING
-- =====================================================================================
addplugin("https://github.com/neovim/nvim-lspconfig")
vim.lsp.config.gopls = {
  settings = {
    gopls = {
      directoryFilters = { '-**/node_modules', '-**/.docker', '-**/bin' },
      semanticTokens = true,
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
      -- go.diagnostic.vulncheck = "Imports"
      analyses = { unusedparams = true },
      vulncheck = 'Imports',
    },
  },
}
vim.lsp.enable({ 'gopls', 'pyright', 'bashls', 'rust-analyzer' })
vim.lsp.inlay_hint.enable(true)

-- Navigation (VS Code: F12 / Alt+F12 peek / Shift+F12 references). Buffer-local, set when an LSP attaches.
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('migrated_lsp', { clear = true }),
  callback = function(ev)
    local t = require('telescope.builtin')
    local o = function(desc) return { buffer = ev.buf, desc = desc } end
    local m = vim.keymap.set
    m('n', 'gd', vim.lsp.buf.definition, o('Go to definition'))
    m('n', 'gD', function() t.lsp_definitions({ jump_type = 'never' }) end, o('Peek definition'))
    m('n', 'gi', vim.lsp.buf.implementation, o('Go to implementation'))
    m('n', 'g]', vim.lsp.buf.implementation, o('Go to implementation'))
    m('n', 'gI', function() t.lsp_implementations({ jump_type = 'never' }) end, o('Peek implementations'))
    m('n', 'gy', vim.lsp.buf.type_definition, o('Go to type definition'))
    m('n', 'gR', function() t.lsp_references({ jump_type = 'never' }) end, o('References (list + preview)'))
    m('n', 'gh', vim.lsp.buf.hover, o('Hover'))
    m('n', '<leader>o', t.lsp_document_symbols, o('Document symbols'))
    m('n', '<leader>O', t.lsp_dynamic_workspace_symbols, o('Workspace symbols'))
    m('n', '<leader>rn', vim.lsp.buf.rename, o('Rename'))
    m('n', '<leader>.', vim.lsp.buf.code_action, o('Code action'))
  end,
})

addplugin("https://github.com/stevearc/conform.nvim" )
require("conform").setup({
  formatters_by_ft = {
    python = { "black" },
    go = { "goimports", "gofmt" },
    rust = { "rustfmt" }
  },
  format_on_save = { timeout_ms = 3000, lsp_format = "fallback" },
})

-- =====================================================================================
-- AUTOCMDS
-- =====================================================================================
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight_yank', {}),
  desc = 'Hightlight selection on yank',
  pattern = '*',
  callback = function()
    vim.highlight.on_yank { higroup = 'IncSearch', timeout = 500 }
  end,
})

local aug = vim.api.nvim_create_augroup('migrated', { clear = true })
vim.api.nvim_create_autocmd('BufWritePre', { -- files.trimTrailingWhitespace / trimFinalNewlines
  group = aug,
  callback = function()
    local view = vim.fn.winsaveview()
    vim.cmd([[keeppatterns silent! %s/\s\+$//e]])
    vim.cmd([[keeppatterns silent! %s/\($\n\s*\)\+\%$//e]])
    vim.fn.winrestview(view)
  end,
})

-- vim: ts=2 sts=2 sw=2 et
