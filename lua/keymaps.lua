-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Line Diagnostics ([e]rror)' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

vim.keymap.set('n', '<leader><leader>', '<c-w><c-w>', { desc = 'Other Window' })
vim.keymap.set('n', '<leader>w', '<cmd>w<CR>', { desc = 'Save' })

vim.keymap.set('i', 'jj', '<ESC>')
vim.keymap.set('c', 'jj', '<C-c>')

-- use text object like 'ciw'
vim.keymap.set('v', 'i', '<Nop>')

vim.keymap.set('x', 'mp', [["_dP]])
vim.keymap.set({ 'n', 'v' }, 'md', [["_d]], { desc = '"_d' })
vim.keymap.set({ 'n', 'v' }, 'mc', [["_c]], { desc = '"_c' })

vim.keymap.set('n', 'mx', [[<cmd>.s/\[\s\]/[x]<cr>]], { desc = 'Mark as Done' })
vim.keymap.set('n', 'm[', [[<cmd>.s/\(\s*\)-\?\s*/\1- [ ] /| nohl<cr>]], { desc = 'Add - [ ]' })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.keymap.set('n', '<leader>y', function()
  local line_number = vim.api.nvim_win_get_cursor(0)[1]
  local line_text = vim.api.nvim_buf_get_lines(0, line_number - 1, line_number, false)[1]
  local url_pattern = 'https?://[%w-_%.%?%.:/%+=&#]+'
  local url = line_text:match(url_pattern)

  if url then
    vim.fn.setreg('+', url)
    vim.notify('Copied to clipboard: ' .. url, vim.log.levels.INFO)
  end
end)

-- vim: ts=2 sts=2 sw=2 et
