return {
  run_command_and_notify = function(cmd, args)
    vim.notify(vim.inspect(vim.list_extend({ cmd }, args or {})), vim.log.levels.DEBUG)
    local Job = require 'plenary.job'
    Job:new({
      command = cmd,
      args = args,
      on_exit = function(job, return_code)
        local result = table.concat(job:result(), '\n')
        vim.schedule(function()
          if return_code == 0 then
            vim.notify('Command succeeded:\n' .. result, vim.log.levels.INFO)
          else
            vim.notify('Command failed with exit code ' .. return_code .. ':\n' .. result, vim.log.levels.ERROR)
          end
        end)
      end,
      on_stderr = function(job, data, _)
        vim.schedule(function()
          vim.notify('Error: ' .. data, vim.log.levels.ERROR)
        end)
      end,
    }):start()
  end,
}
