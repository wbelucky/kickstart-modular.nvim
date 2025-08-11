-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim
local icons = require('icons').git

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  cmd = 'Neotree',
  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
    {
      '<leader>t',
      function()
        -- require('neo-tree.command').execute { toggle = true, dir = vim.fn.expand '%:p:h' }
        local git_utils = require 'neo-tree.git.utils'
        local current_file = vim.fn.expand '%:p'

        if current_file ~= '' then
          local current_dir = vim.fn.fnamemodify(current_file, ':h')
          local git_root = git_utils.get_repository_root(current_dir)
          require('neo-tree.command').execute {
            dir = git_root,
            reveal_file = current_file,
            toggle = true,
          }
        else
          -- 現在のファイルがない場合は現在の作業ディレクトリを使用
          local git_root = git_utils.get_repository_root(vim.fn.getcwd())
          if git_root then
            require('neo-tree.command').execute {
              dir = git_root,
              toggle = true,
            }
          end
        end
      end,
      desc = 'NeoTree Around File',
    },
  },

  opts = {
    buffers = {
      follow_current_file = {
        enabled = true,
      },
    },
    window = {
      mappings = {
        ['h'] = 'navigate_up',
        ['l'] = 'open',
        ['gh'] = 'focus_preview',
      },
    },
    filesystem = {
      bind_to_cwd = true,
      window = {
        mappings = {
          ['\\'] = 'close_window',
        },
      },
      filtered_items = {
        hide_dotfiles = false,
        hide_gitignored = false,
      },
      follow_current_file = {
        enabled = true,
        leave_dirs_open = false,
      },
    },
    default_component_configs = {
      git_status = {
        symbols = {
          -- Change type
          added = '✚',
          deleted = icons.deleted,
          modified = '',
          renamed = icons.renamed,
          -- Status type
          untracked = icons.untracked,
          ignored = '',
          unstaged = icons.changed,
          staged = icons.added,
          conflict = icons.unmerged,
        },
      },
    },
  },
}
