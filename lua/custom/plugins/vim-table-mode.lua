local prefix = '<leader>\\|'
return {
  'dhruvasagar/vim-table-mode',
  ft = { 'markdown' },
  keys = {
    -- https://github.com/dhruvasagar/vim-table-mode/blob/master/plugin/table-mode.vim
    -- https://gemini.google.com/app/6e95059629b6d737
    {
      prefix .. 'r',
      desc = '[T]able_mode_[r]ealign_map',
    },
    {
      prefix .. 'dd',
      desc = '[T]able_mode_[d]elete_[d]elete_row_map',
    },
    {
      prefix .. 'dc',
      desc = '[T]able_mode_[d]elete_[c]olumn_map',
    },
    {
      prefix .. 'iC',
      desc = '[T]able_mode_[i]nsert_[C]olumn_before_map',
    },
    {
      prefix .. 'ic',
      desc = '[T]able_mode_[i]nsert_[c]olumn_after_map',
    },
    {
      prefix .. 'fa',
      desc = '[T]able_mode_[f]ormula_[a]dd_formula_map',
    },
    {
      prefix .. 'fe',
      desc = '[T]able_mode_[f]ormula_[e]val_formula_map',
    },
    {
      prefix .. '?',
      desc = '[T]able_mode_echo_cell_map',
    },
    {
      prefix .. 's',
      desc = '[T]able_mode_[s]ort_map',
    },
    {
      prefix .. 't',
      desc = '[T]able_mode_[t]ableize_map',
    },
  },
  init = function()
    -- vim.g.table_mode_disable_mappings = 1
    -- vim.g.table_mode_disable_tableize_mappings = 1
    vim.g.table_mode_map_prefix = prefix
    -- require('vim-table-mode').setup {}
  end,
}
