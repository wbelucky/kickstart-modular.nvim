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
vim.keymap.set('n', '<leader>x', '<cmd>x<CR>', { desc = 'Save and Quit' })

vim.keymap.set('i', 'jj', '<ESC>')
vim.keymap.set('c', 'jj', '<C-c>')

-- use text object like 'ciw'
vim.keymap.set('v', 'i', '<Nop>')

vim.keymap.set('x', 'mp', [["_dP]])
vim.keymap.set({ 'n', 'v' }, 'md', [["_d]], { desc = '"_d' })
vim.keymap.set({ 'n', 'v' }, 'mc', [["_c]], { desc = '"_c' })

vim.keymap.set('v', '<leader>b', function()
  local mode = vim.api.nvim_get_mode().mode
  vim.cmd 'normal :'

  local start_row, start_col = unpack(vim.api.nvim_buf_get_mark(0, '<'))
  local end_row, end_col = unpack(vim.api.nvim_buf_get_mark(0, '>'))

  local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)

  if mode == 'V' then
    table.insert(lines, 1, '```sh')
    table.insert(lines, '```')
  else
    local last_idx = end_row - start_row + 1
    local last_line_len = string.len(lines[last_idx])
    if end_col >= last_line_len then
      end_col = last_line_len - 1
    end

    do
      local first_line = string.sub(lines[1], 0, start_col)
      if start_col ~= 0 then
        first_line = first_line .. ' '
      end
      first_line = first_line .. '`' .. string.sub(lines[1], start_col + 1, -1)
      lines[1] = first_line
    end

    do
      local last_line = string.sub(lines[last_idx], 0, end_col - last_line_len) .. '`'
      if end_col + 2 <= last_line_len then
        last_line = last_line .. ' ' .. string.sub(lines[last_idx], end_col - last_line_len + 1, -1)
      end
      lines[last_idx] = last_line
    end
  end

  vim.api.nvim_buf_set_lines(0, start_row - 1, end_row, false, lines)
end, { desc = 'Wrap selection in Markdown code block' })

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

vim.api.nvim_create_user_command('DiffOrig', function()
  -- 現在のバッファ名を取得
  local filename = vim.fn.expand('%:p')
  if filename == '' then
    print("No file associated with this buffer.")
    return
  end

  -- 新しい垂直分割ウィンドウを開く
  -- TODO: filetypeを引き継ぎたい
  vim.cmd('vert new')
  -- 新しいバッファをファイルタイプなし、非ファイルとして設定
  vim.opt_local.buftype = 'nofile'
  vim.opt_local.bufhidden = 'wipe' -- ウィンドウを閉じたらバッファも削除
  -- 元のファイルを読み込む
  vim.cmd('read ++edit ' .. vim.fn.fnameescape(filename))
  -- 変更をすべて削除 (元のファイルの内容だけにするため)
  vim.cmd('silent 0d_') -- 0行目から現在行まで削除

  -- diff モードにする
  vim.cmd('diffthis')

  -- 元のウィンドウに戻る
  vim.cmd('wincmd p')
  -- 元のウィンドウも diff モードにする
  vim.cmd('diffthis')
end, { nargs = 0, desc = "Show diff between current buffer and saved file" })
vim.keymap.set('n', 'mt', [[<cmd>.s/\(\s*\)-\?\s*/\1- [ ] /| nohl<cr>]], { desc = 'Add - [ ]' })
vim.keymap.set('n', '<leader>rs', function()
  print(vim.inspect(vim.system({ 's-start.sh', vim.api.nvim_buf_get_name(0), vim.fn.getline '.' }):wait()))
  vim.api.nvim_command 'checktime'
end, { desc = '[r]ecord session [s]tart' })
vim.keymap.set('n', '<leader>re', ':<c-u>!s-end.sh %:p<cr>', { desc = '[r]ecord session [e]nd' })
vim.keymap.set('n', 'mt', [[<cmd>.s/\(\s*\)-\?\s*/\1- [ ] /| nohl|norm a<cr>]], { desc = 'add - [ ]' })
vim.keymap.set('n', 'mx', function()
  local current_line_num = vim.fn.line '.'
  local current_line = vim.fn.getline(current_line_num)

  if current_line:match '^%s*%- %[ %] .*' then
    local date_str = os.date '%Y-%m-%d'
    local new_line = current_line:gsub('^%s*%- %[ %]', '- [x] ' .. date_str)

    vim.api.nvim_buf_set_lines(0, current_line_num - 1, current_line_num, false, { new_line })

    print 'Task marked as done with date.'
  else
    -- マッチしない場合はメッセージを表示
    print 'Current line is not an unchecked markdown task.'
  end
end, { desc = 'Complete Markdown Task' })
-- vim: ts=2 sts=2 sw=2 et
