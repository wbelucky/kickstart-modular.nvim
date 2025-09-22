-- NOTE: Plugins can specify dependencies.
--
-- The dependencies are proper plugin specifications as well - anything
-- you do for a plugin at the top level, you can do for a dependency.
--
-- Use the `dependencies` key to specify the dependencies of a particular plugin

return {
  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        'nvim-telescope/telescope-fzf-native.nvim',

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = 'make',

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },

      -- Useful for getting pretty icons, but requires a Nerd Font.
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
      { 'nvim-telescope/telescope-ghq.nvim' },
    },
    config = function()
      -- Telescope is a fuzzy finder that comes with a lot of different things that
      -- it can fuzzy find! It's more than just a "file finder", it can search
      -- many different aspects of Neovim, your workspace, LSP, and more!
      --
      -- The easiest way to use Telescope, is to start by doing something like:
      --  :Telescope help_tags
      --
      -- After running this command, a window will open up and you're able to
      -- type in the prompt window. You'll see a list of `help_tags` options and
      -- a corresponding preview of the help.
      --
      -- Two important keymaps to use while in Telescope are:
      --  - Insert mode: <c-/>
      --  - Normal mode: ?
      --
      -- This opens a window that shows you all of the keymaps for the current
      -- Telescope picker. This is really useful to discover what Telescope can
      -- do as well as how to actually do it!

      local actions = require 'telescope.actions'
      -- TODO:: iconの意味について, のchangedとunstagedを混同しているところがあるので検討
      local git_icons = require('icons').git
      -- [[ Configure Telescope ]]
      -- See `:help telescope` and `:help telescope.setup()`
      require('telescope').setup {
        -- You can put your default mappings / updates / etc. in here
        --  All the info you're looking for is in `:help telescope.setup()`
        --
        -- defaults = {
        --   mappings = {
        --     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
        --   },
        -- },
        defaults = vim.tbl_extend(
          'force',
          require('telescope.themes').get_ivy(), -- or get_cursor, get_ivy
          {
            --- other `default` options go here
            mappings = {
              i = {
                ['<ScrollWheelUp>'] = actions.results_scrolling_up,
                ['<ScrollWheelDown>'] = actions.results_scrolling_down,
              },
            },
          }
        ),

        pickers = {
          git_status = {
            git_icons = git_icons,
            initial_mode = 'normal',
          },
        },
        extensions = {
          ['ui-select'] = {
            -- TODO:
            require('telescope.themes').get_dropdown(),
          },
        },
      }

      -- Enable Telescope extensions if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')
      pcall(require('telescope').load_extension, 'ghq')

      -- See `:help telescope.builtin`
      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>p', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>saf', function()
        builtin.find_files { cwd = vim.fn.expand '%:p:h' }
      end, { desc = '[S]earch [A]round [F]iles' })
      vim.keymap.set('n', '<leader>sag', function()
        builtin.live_grep { cwd = vim.fn.expand '%:p:h' }
      end, { desc = '[S]earch [A]round with [G]rep' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader>b', builtin.buffers, { desc = 'Search existing [B]uffers' })

      vim.keymap.set('n', '<leader>gs', function()
        require('telescope.builtin').git_status { cwd = vim.fn.expand '%:p:h' }
      end, { desc = '[G]it [S]tatus' })

      -- Slightly advanced example of overriding default behavior and theme
      vim.keymap.set('n', '<leader>/', function()
        -- You can pass additional configuration to Telescope to change the theme, layout, etc.
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      -- It's also possible to pass additional configuration options.
      --  See `:help telescope.builtin.live_grep()` for information about particular keys
      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[S]earch [/] in Open Files' })

      -- Shortcut for searching your Neovim configuration files
      vim.keymap.set('n', '<leader>sc', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[S]earch Neovim Configs' })

      vim.keymap.set('n', '<leader>gq', function()
        require('telescope').extensions.ghq.list()
      end, { desc = 'List Git Repositories under [G]H[Q]' })

      vim.keymap.set('n', '<leader>rP', function(ops)
        opts = opts or {}
        opts.entry_maker = function(entry) -- EntryMaker: 入力は finder の返す文字列
          local metadata = vim.json.decode(entry) -- json を Lua のテーブルに変換
          local display = metadata.title .. ' ' .. metadata.metadata.redmine.issue_id
          return {
            value = metadata, -- あとから displayer などで使うためフルの情報を渡しておく
            ordinal = display, -- 検索対象として使われる文字列
            display = display, -- 画面上に表示される文字列
            path = metadata.absPath, -- 選択したときに開くファイルのパス
          }
        end
        local cmd = { 'zk', 'list', '-t', 'rm-milestone', '-f', 'jsonl', '--quiet', '--no-pager' }
        pickers
          .new(opts, {
            prompt_title = 'tags=rm-milestone',
            finder = finders.new_oneshot_job(cmd, opts), -- opts 経由で EntryMaker が渡される。
            sorter = conf.generic_sorter(opts),
            attach_mappings = function(prompt_bufnr, map)
              actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                print(vim.inspect(vim
                  .system({
                    'rm-md',
                    'parent',
                    vim.api.nvim_buf_get_name(0),
                    selection.value.metadata.redmine.issue_id,
                  })
                  :wait()))
                vim.api.nvim_command 'checktime'
              end)
              return true
            end,
          })
          :find()
      end, { desc = 'tags=rm-milestone' })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
