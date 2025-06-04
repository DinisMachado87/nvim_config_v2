return {
  'MoulatiMehdi/42norm.nvim',
  config = function()
    local norm = require '42norm'

    -- Configure the plugin
    norm.setup {
      header_on_save = true,
      format_on_save = false,
      liner_on_change = true,
    }

    -- Set up keymaps
    vim.keymap.set('n', '<F5>', function()
      norm.check_norms()
    end, { desc = 'Update 42norms diagnostics', noremap = true, silent = true })

    vim.keymap.set('n', '<C-f>', function()
      norm.format()
    end, { desc = 'Format buffer on 42norms', noremap = true, silent = true })

    vim.keymap.set('n', '<F1>', function()
      norm.stdheader()
    end, { desc = 'Insert 42header', noremap = true, silent = true })

    -- Create user commands
    vim.api.nvim_create_user_command('Norminette', function()
      norm.check_norms()
    end, {})

    vim.api.nvim_create_user_command('Format', function()
      norm.format()
    end, {})

    vim.api.nvim_create_user_command('Stdheader', function()
      norm.stdheader()
    end, {})
  end,
}
