local function zk_lcd(options)
  local util = require 'zk.util'
  options = options or {}
  local notebook_path = options.notebook_path or util.resolve_notebook_path(0)
  if notebook_path == nil then
    vim.notify('notebook_path is nil', vim.log.levels.ERROR, {})
    return
  end
  local root = util.notebook_root(notebook_path)
  if root then
    vim.cmd('lcd ' .. root)
  end
end

local function zk_lcd_and_edit(options, picker_options)
  return function(notes)
    if picker_options and picker_options.multi_select == false then
      notes = { notes }
    end
    for _, note in ipairs(notes) do
      options.edit_callback(options, note.absPath)
    end
  end
end

---@param options? table additional options
---@param picker_options? table options for the picker
---@param cb function
local function pickTodoOrInProgress(options, picker_options, cb)
  local ui = require 'zk.ui'
  local api = require 'zk.api'
  ---@see zk.ui.pick_notes
  options = vim.tbl_extend('force', { select = ui.get_pick_notes_list_api_selection(picker_options or {}) },
    options or {})

  -- FIXME: use coroutine
  api.list(options.notebook_path, vim.tbl_extend('force', options, { tags = { 'todo' } }), function(errToDo, notesToDo)
    assert(not errToDo, tostring(errToDo))

    api.list(options.notebook_path, vim.tbl_extend('force', options, { tags = { 'in-progress' } }),
      function(errInProgress, notesInProgress)
        assert(not errInProgress, tostring(errInProgress))
        ui.pick_notes(vim.list_extend(notesInProgress, notesToDo), picker_options, cb)
      end)
  end)
end

---@param options? table additional options
---@param picker_options? table options for the picker
---@see https://github.com/zk-org/zk/blob/main/docs/editors-integration.md#zklist
---@see zk.ui.pick_notes
local function editTodoOrInProgress(options, picker_options)
  pickTodoOrInProgress(options, picker_options, zk_lcd_and_edit(options, picker_options))
end

local function get_selected_lines()
  local region = vim.region(0, "'<", "'>", vim.fn.visualmode(), true)

  local chunks = {}
  local maxcol = vim.v.maxcol
  for line, cols in vim.spairs(region) do
    local endcol = cols[2] == maxcol and -1 or cols[2]
    local chunk = vim.api.nvim_buf_get_text(0, line, cols[1], line, endcol, {})[1]
    table.insert(chunks, chunk)
  end
  return chunks
end

---@param lines string[]
---@return string|nil title
---@return string[] body_lines
local function reduce_headings(lines)
  local h1_title = nil
  local reduce_count = 0
  local first_content_line_num = nil

  ---@param i integer
  local function processLines(i)
    local line = lines[i]

    local hashes, title = string.match(line, '^(#+) (%S.*)')

    -- TODO: なぜかtitleのときにこれが表示されない.
    -- print(vim.inspect { hashes, title })

    if first_content_line_num == nil and string.match(line, '%S') ~= nil then
      first_content_line_num = i

      if hashes ~= nil then
        h1_title = title
        reduce_count = string.len(hashes) - 1
      else
        h1_title = line
      end

      lines[i] = ''
      return
    end

    if hashes ~= nil and h1_title ~= nil then
      local hash_num = math.max(string.len(hashes) - reduce_count, 2)
      hashes = string.rep('#', hash_num)
      lines[i] = hashes .. ' ' .. title
      return
    end
  end

  for i, _ in ipairs(lines) do
    processLines(i)
  end

  return h1_title, vim.list_slice(lines, first_content_line_num + 1)
end

local function zk_new_partial_md(options)
  local util = require 'zk.util'

  local location = util.get_lsp_location_from_selection()
  local selected_text = get_selected_lines()
  assert(selected_text ~= nil, 'No selected text')

  local title, body = reduce_headings(selected_text)

  options = options or {}
  options.title = title or 'title'
  options.content = table.concat(body, '\n')

  if options.inline == true then
    options.inline = nil
    options.dryRun = true
    options.insertContentAtLocation = location
  else
    options.insertLinkAtLocation = location
  end

  require('zk').new(options)
end

---@type LazySpec
local spec = {
  'zk-org/zk-nvim',
  version = 'v0.2.0',
  keys = {
    {
      '<leader>mw',
      function()
        require('zk.commands').get 'ZkNew' {
          group = 'weekly',
          dir = 'weekly',
        }
      end,
      desc = 'Weekly',
    },
    {
      '<leader>mj',
      function()
        require('zk.commands').get 'ZkNew' {
          group = 'journal',
          dir = 'journal',
        }
      end,
      desc = 'Journal',
    },
    {
      '<leader>md',
      function()
        require('zk.commands').get 'ZkNew' {
          group = 'diary',
          dir = 'diary',
        }
      end,
      desc = 'Diary',
    },
    {
      '<leader>mk',
      function()
        require('zk.commands').get 'ZkNew' {
          group = 'kanban',
          dir = 'kanban',
        }
      end,
      desc = 'Kanban',
    },
    {
      '<leader>mn',
      function()
        require('zk.commands').get 'ZkNotes' {
          tags = { 'next' },
        }
      end,
      desc = 'Zk [N]ext Actions',
    },
    {
      '<leader>mp',
      function()
        require('zk.commands').get 'ZkNotes' {
          tags = { 'project OR scheduled OR waiting', 'NOT done', 'NOT abort' },
        }
      end,
      desc = 'Zk Projects',
    },
    {
      '<leader>my',
      function()
        vim.cmd 'normal :'
        zk_new_partial_md {
          group = 'posts',
          dir = 'posts',
          extra = {
            -- tags = "tag1\ntag2",
            tags = 'next',
          },
        }
      end,
      desc = 'Zk yank from partial md',
      mode = 'v',
    },
    {
      '<leader>mt',
      function()
        require('zk.commands').get 'ZkTags' {}
      end,
      desc = 'Zk Tags',
      mode = 'n',
    },
    {
      '<leader>mi',
      function()
        require('zk.commands').get 'ZkInsertLink' {}
      end,
      desc = 'ZkInsertLink',
      mode = 'n',
    },
    {
      '<leader>ms',
      function()
        -- this is ok, but i want to sort by tag
        -- require("zk.commands").get "ZkNotes" {
        --   tags = ["todo OR in-progress"]
        -- }

        editTodoOrInProgress({}, { title = 'Zk on Sprint' })
      end,
      desc = 'Zk Sprint',
      mode = 'n',
    },
    {
      '<leader>mb',
      function()
        require('zk.commands').get 'ZkBacklinks' {}
      end,
      desc = 'Zk Backlinks',
      mode = 'n',
    },
    {
      '<leader>mr',
      function()
        require('zk.commands').get 'ZkNotes' {
          sort = { 'modified-' },
          modifiedAfter = 'last one week',
        }
      end,
      desc = 'Zk Recent',
      mode = 'n',
    },
  },
  init = function()
    local subcommands = { '%', 'start' }
    vim.api.nvim_create_user_command('Sche', function(args)
      if args.fargs[1] == '%' then
        table.remove(args.fargs, 1)
        require('zk.api').list(nil, { select = { 'title', 'path' }, hrefs = { vim.api.nvim_buf_get_name(0) } },
          function(err, notes)
            assert(not err, tostring(err))
            local title = notes[1].title
            local path = notes[1].path
            require('util.async-command').run_command_and_notify(
              'pomodolo-calendar',
              vim.list_extend(
                { 'start', '-s', title, '-l', 'http://main.tail89b25.ts.net:3000/blog/' ..
                string.gsub(path, '%.[^%.]+$', '') }, args.fargs)
            )
          end)
      else
        require('util.async-command').run_command_and_notify('pomodolo-calendar', args.fargs)
      end
    end, {
      nargs = '*',
      complete = function(arg_lead, cmd_line, cursor_pos)
        return vim.tbl_filter(function(subcmd)
          return vim.startswith(subcmd, arg_lead) -- 入力された文字でフィルタリング
        end, subcommands)
      end,
    })
  end,
  config = function()
    local zk = require('zk')
    local api = require 'zk.api'
    local config = require('zk.config')

    local default_edit_cb = function(options, paths)
      for _, path in ipairs(paths) do
        vim.cmd("edit " .. path)
      end
    end

    config.defaults.edit_callback = default_edit_cb
    config.options.edit_callback = default_edit_cb


    -- injections for edit_callback to zk.new & zk.api

    zk.new = function(options)
      options = options or {}
      api.new(options.notebook_path, options, function(err, res)
        assert(not err, tostring(err))
        if options and options.dryRun ~= true and options.edit ~= false then
          config.options.edit_callback(options, { res.path })
        end
      end)
    end

    zk.edit = function(options, picker_options)
      zk.pick_notes(options, picker_options, function(notes)
        if picker_options and picker_options.multi_select == false then
          notes = { notes }
        end
        config.options.edit_callback(options, vim.tbl_map(function(note) return note.absPath end, notes))
      end)
    end

    require('zk').setup {
      picker = 'telescope',
      edit_callback = function(options, paths)
        zk_lcd(options)
        for _, path in ipairs(paths) do
          vim.cmd('edit ' .. path)
        end
      end,
    }

    local actions = require 'telescope.actions'
    local action_state = require 'telescope.actions.state'
    local builtin = require 'telescope.builtin'
    -- local pickers = require 'telescope.pickers' -- picker 作成用の API
    -- local finders = require 'telescope.finders' -- finder 作成用の API
    -- local conf = require('telescope.config').values -- ユーザーの init.lua を反映した設定内容
    -- TODO: templateを選択して選択範囲をtitleとbodyに持つようなnoteを作成したい
    -- TODO: できれば動かしたい。zkとtelescopeに依存するので、lazyのconfigを切り出す? どちらかをどちらかに依存させる?
    vim.keymap.set('v', '<leader>mT', function(ops)
      -- opts = opts or {}
      -- -- TODO:
      -- local cmd = { 'zk', 'list', '-t', 'rm-milestone', '-f', 'jsonl', '--quiet', '--no-pager' }
      -- opts.entry_maker = function(entry) -- EntryMaker: 入力は finder の返す文字列
      --   local metadata = vim.json.decode(entry) -- json を Lua のテーブルに変換
      --   local display = metadata.title .. ' ' .. metadata.metadata.redmine.issue_id
      --   return {
      --     value = metadata, -- あとから displayer などで使うためフルの情報を渡しておく
      --     ordinal = display, -- 検索対象として使われる文字列
      --     display = display, -- 画面上に表示される文字列
      --     path = metadata.absPath, -- 選択したときに開くファイルのパス
      --   }
      -- end
      -- pickers
      --   .new(opts, {
      --     prompt_title = 'tags=rm-milestone',
      --     finder = finders.new_oneshot_job(cmd, opts), -- opts 経由で EntryMaker が渡される。
      --     sorter = conf.generic_sorter(opts),
      --     attach_mappings = function(prompt_bufnr, map)
      --       actions.select_default:replace(function()
      --         actions.close(prompt_bufnr)
      --         local selection = action_state.get_selected_entry()
      --         print(vim.inspect(vim
      --           .system({
      --             'rm-md',
      --             'parent',
      --             vim.api.nvim_buf_get_name(0),
      --             selection.value.metadata.redmine.issue_id,
      --           })
      --           :wait()))
      --         vim.api.nvim_command 'checktime'
      --       end)
      --       return true
      --     end,
      --   })
      --   :find()
      local zk_dir = os.getenv 'ZK_NOTEBOOK_DIR'
      if not zk_dir or zk_dir == '' then
        print 'Error: ZK_NOTEBOOK_DIR is not set.'
        return
      end

      local template_path = zk_dir .. '/.zk/templates'

      -- Telescopeのfind_filesを特定のディレクトリで実行
      builtin.find_files {
        prompt_title = 'ZK Templates',
        cwd = template_path, -- 検索対象のディレクトリを指定
        hidden = true, -- ドットファイルも含める場合
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()

            local input_data = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')

            -- vim.system({ 'yq', '--front-matter=extract', [[.redmine.issue_id]] }, { stdin = input_data }, function(obj)
            --   vim.schedule(function()
            --     if obj.code == 0 then
            --       -- TODO:
            --       print(obj.stdout)
            --     else
            --       vim.notify('yq error: ' .. obj.stderr, vim.log.levels.ERROR)
            --     end
            --   end)
            -- end)
            -- 選択したファイルのフルパスを読み込んで現在のカーソル位置に挿入
            zk_new_partial_md {
              group = 'posts',
              dir = 'posts',
              template = selection.path,
              extra = {
                -- tags = "tag1\ntag2",
                tags = 'next',
              },
            }
          end)
          -- ここで選択時の挙動をカスタマイズすることも可能
          return true
        end,
      }
    end, { desc = 'tags=rm-milestone' })
  end,
}

return spec
