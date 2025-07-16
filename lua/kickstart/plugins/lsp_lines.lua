return {
  'https://git.sr.ht/~whynothugo/lsp_lines.nvim',
  event = 'LspAttach',
  config = function()
    require('lsp_lines').setup()

    -- Disable virtual_text since lsp_lines shows diagnostics
    vim.diagnostic.config {
      virtual_text = false,
    }
  end,
  keys = {
    {
      '<leader>tl',
      function()
        require('lsp_lines').toggle()
      end,
      desc = 'Toggle lsp_lines',
    },
  },
}
