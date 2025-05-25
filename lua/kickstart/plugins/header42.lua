return {
  "Diogo-ss/42-header.nvim",
  cmd = { "Stdheader" },
  keys = { "<F1>" },
  opts = {
    default_map = true,
    auto_update = true,
    user = "dimachad",
    mail = "dimachad@student.42berlin.d"
  },
  config = function(_, opts)
    require("42header").setup(opts)

    vim.api.nvim_create_user_command(
      'Header',
      function()
        require("42header").insert_header()
      end,
      {}
    )

    vim.api.nvim_set_keymap('n', '<F2>', ':Header<CR>', { noremap = true, silent = true })
  end
}

