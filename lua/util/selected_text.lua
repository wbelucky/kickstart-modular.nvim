-- https://www.reddit.com/r/neovim/comments/1hmpqga/get_selected_text_in_lua/
return function()
  local mode = vim.api.nvim_get_mode().mode
  local opts = {}
  -- \22 is an escaped version of <c-v>
  if mode == 'v' or mode == 'V' or mode == '\22' then
    opts.type = mode
  end
  return vim.fn.getregion(vim.fn.getpos 'v', vim.fn.getpos '.', opts)
end
