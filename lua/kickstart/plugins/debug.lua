-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'theHamsta/nvim-dap-virtual-text',
    'nvim-neotest/nvim-nio',
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',
    'leoluz/nvim-dap-go',
  },
  keys = function()
    local dap = require 'dap'
    return {
      { '<F1>', dap.step_into, desc = 'Debug: Step Into' },
      { '<F2>', dap.step_over, desc = 'Debug: Step Over' },
      { '<F3>', dap.step_out, desc = 'Debug: Step Out' },
      { '<F5>', dap.continue, desc = 'Debug: Start/Continue' },

      { '<F8>', dap.terminate, desc = 'Debug: Terminate session' },

      { '<F7>', require('dapui').toggle, desc = 'Debug: Toggle DAP UI panels' },
      { '<leader>dv', require('nvim-dap-virtual-text').toggle, desc = 'Debug: Toggle virtual text' },

      { '<leader>b', dap.toggle_breakpoint, desc = 'Debug: Toggle Breakpoint' },
      {
        '<leader>B',
        function()
          dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
        end,
        desc = 'Debug: Set Breakpoint',
      },
    }
  end,

  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    -- Manual dap-ui setup, no automatic open
    dapui.setup()

    -- Manual virtual text setup (off by default)
    require('nvim-dap-virtual-text').setup {
      enabled = false, -- virtual text starts off
      commented = true,
    }

    -- Disable automatic DAP UI open/close
    -- (Remove listeners that auto-open and auto-close panels)
    dap.listeners.after.event_initialized['dapui_config'] = nil
    dap.listeners.before.event_terminated['dapui_config'] = nil
    dap.listeners.before.event_exited['dapui_config'] = nil

    -- Mason setup
    require('mason-nvim-dap').setup {
      automatic_installation = true,
      ensure_installed = { 'lldb', 'delve', 'debugpy' },
    }

    -- Adapter setup (C/C++)
    dap.adapters.codelldb = {
      type = 'server',
      port = '${port}',
      executable = {
        command = vim.fn.stdpath 'data' .. '/mason/packages/codelldb/extension/adapter/codelldb',
        args = { '--port', '${port}' },
      },
    }

    dap.configurations.c = {
      {
        name = 'Launch file',
        type = 'codelldb',
        request = 'launch',
        program = function()
          return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
        args = function()
          local args_string = vim.fn.input 'Arguments: '
          return vim.split(args_string, ' ')
        end,
      },
    }

    dap.configurations.cpp = dap.configurations.c

    -- Go
    require('dap-go').setup {
      delve = { detached = vim.fn.has 'win32' == 0 },
    }

    -- Python adapter (using debugpy directly)
    dap.adapters.debugpy = {
      type = 'executable',
      command = 'python', -- Changed from Mason path to system python
      args = { '-m', 'debugpy.adapter' },
    }

    -- Python configurations
    dap.configurations.python = {
      {
        type = 'debugpy',
        request = 'launch',
        name = 'Launch file',
        program = '${file}',
        pythonPath = function()
          return 'python'
        end,
      },
      {
        type = 'debugpy',
        request = 'launch',
        name = 'Launch file with arguments',
        program = '${file}',
        args = function()
          local args_string = vim.fn.input 'Arguments: '
          return vim.split(args_string, ' ')
        end,
        pythonPath = function()
          return 'python'
        end,
      },
    }
  end,
}
