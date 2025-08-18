return {
  -- Make sure to set this up properly if you have lazy=true
  'MeanderingProgrammer/render-markdown.nvim',
  opts = {
    file_types = { 'markdown', 'Avante' },
    html = {
      comment = {
        conceal = false,
      },
    },
  },
  ft = { 'markdown', 'Avante' },
}
