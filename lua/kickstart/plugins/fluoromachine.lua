return {
  {
    'maxmx03/fluoromachine.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      require('fluoromachine').setup({
        glow = false,
        theme = 'fluoromachine',
        transparent = true,
      })
      vim.cmd.colorscheme('fluoromachine')
    end,
  },
}
