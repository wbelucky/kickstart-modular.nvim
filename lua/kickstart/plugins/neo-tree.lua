-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

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
        require('neo-tree.command').execute { toggle = true, dir = vim.fn.expand '%:p:h' }
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
  },
}
