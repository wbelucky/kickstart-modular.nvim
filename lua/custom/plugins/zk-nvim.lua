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

-- https://github.com/zk-org/zk-nvim/blob/8df80d0dc2d66e53b08740361a600746a6e4edcf/lua/zk/util.lua#L45C1-L63C4
local function get_offset_encoding(bufnr)
  -- Modified from nvim's vim.lsp.util._get_offset_encoding()
  vim.validate('bufnr', bufnr, 'number', true)
  local zk_client = vim.lsp.get_clients({ bufnr = bufnr, name = 'zk' })[1]
  local error_level = vim.log.levels.ERROR
  local offset_encoding --- @type 'utf-8'|'utf-16'|'utf-32'
  if zk_client == nil then
    vim.notify_once('No zk client found for this buffer. Using default encoding of utf-16', error_level)
    offset_encoding = 'utf-16'
  elseif zk_client.offset_encoding == nil then
    vim.notify_once(string.format('ZK Client (id: %s) offset_encoding is nil. Do not unset offset_encoding.', zk_client.id), error_level)
  else
    offset_encoding = zk_client.offset_encoding
  end
  return offset_encoding
end

---@param lines string[]
---@return string|nil title
---@return string[] body_lines
local function reduce_headings(lines)
  -- TODO:
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

local function zk_new_from_selected_text(cb_selected_text_to_option)
  -- https://github.com/neovim/neovim/issues/19567
  local start_pos = vim.fn.getpos 'v'
  local end_pos = vim.fn.getpos '.'
  local selected_text = vim.fn.getregion(start_pos, end_pos, { type = vim.fn.mode() })
  -- type Pos = Tuple<int(buffer), int(row), int(col), int>
  -- type Region = Array<Tuple<Pos, Pos>>
  local region = vim.fn.getregionpos(start_pos, end_pos, { type = vim.fn.mode() })
  local params = vim.lsp.util.make_given_range_params(
    { region[1][1][2], region[1][1][3] - 1 },
    { vim.iter(region):last()[2][2], vim.iter(region):last()[2][3] - 1 },
    0,
    get_offset_encoding(0)
  )
  local location = {
    uri = params.textDocument.uri,
    range = params.range,
  }

  assert(selected_text ~= nil or #selected_text == 0, 'No selected text')

  local options = cb_selected_text_to_option(selected_text)

  options = options or {}
  options.title = options.title or 'title'
  -- options.content = table.concat(body, '\n')
  options.content = options.content

  if options.inline == true then
    options.inline = nil
    options.dryRun = true
    options.insertContentAtLocation = location
  else
    options.insertLinkAtLocation = location
  end

  require('zk').new(options)
end

local function zk_new_from_selected_text_default(options)
  zk_new_from_selected_text(function(selected_text)
    local title, body = reduce_headings(selected_text)

    options.title = title
    options.content = table.concat(body, '\n')
    return options
  end)
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
        zk_new_from_selected_text_default {
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
      '<leader>mz',
      function()
        vim.cmd 'normal :'
        zk_new_from_selected_text_default {
          group = 'posts',
          dir = 'posts',
          template = 'vz-jp-qa.md',
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
    local a = require 'plenary.async'
    vim.keymap.set(
      'v',
      '<leader>mT',
      a.void(function(ops)
        local cb_selected_text_to_option = function(selected_text)
          local zk_dir = os.getenv 'ZK_NOTEBOOK_DIR'
          if not zk_dir or zk_dir == '' then
            print 'Error: ZK_NOTEBOOK_DIR is not set.'
            return
          end

          local template_path = zk_dir .. '/.zk/templates'

          local tx, rx = a.control.channel.oneshot()

          a.void(function()
            builtin.find_files {
              prompt_title = 'ZK Templates',
              cwd = template_path,
              hidden = true,
              attach_mappings = function(prompt_bufnr, map)
                actions.select_default:replace(function()
                  actions.close(prompt_bufnr)
                  local selection = action_state.get_selected_entry()
                  tx(selection)
                end)
                return true
              end,
            }
          end)()

          local selection = rx()

          local input_data = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')

          local completed = vim.system({ 'yq', '--front-matter=extract', [[.redmine.issue_id]] }, { text = true, stdin = input_data }):wait(500)

          if completed.code ~= 0 then
            vim.notify('yq error: ' .. completed.stderr, vim.log.levels.ERROR)
            return
          end

          local title, body = reduce_headings(selected_text)

          local template = selection.path:gsub('^%s+', ''):gsub('%s+$', '')

          return {
            title = title,
            content = table.concat(body, '\n'),
            group = 'posts',
            dir = 'posts',
            template = template,
            extra = {
              -- tags = "tag1\ntag2",
              redmine_parent_issue_id = completed.stdout,
            },
          }
        end

        zk_new_from_selected_text(cb_selected_text_to_option)
      end)
    )
  end,
}

return spec
