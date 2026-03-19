return {
  'tpope/vim-projectionist',
  ft = { 'cpp', 'c', 'hpp', 'h' },
  config = function()
    vim.g.projectionist_heuristics = {
      ['*.cpp|*.hpp|*.h'] = {
        ['*.cpp'] = {
          alternate = { '{}.hpp', '{}.h' }, -- Keep original header toggle
          type = 'source',
        },
        ['*.cc'] = {
          alternate = { '{}.hpp', '{}.h', '{}.hh' },
          type = 'source',
        },
        ['*.hpp'] = {
          alternate = { '{}.cpp', '{}.cc' },
          type = 'header',
        },
        ['*.h'] = {
          alternate = { '{}.cpp', '{}.cc', '{}.c' },
          type = 'header',
        },
        ['test_*.cpp'] = {
          alternate = { '{}.cpp' }, -- Test alternates to source
          type = 'test',
        },
      },
    }

    -- Custom function to toggle between source and test
    vim.keymap.set('n', '<leader>tt', function()
      local current_path = vim.fn.expand '%:p:h' -- Directory of current file
      local current_file = vim.fn.expand '%:t' -- Just the filename
      local basename = vim.fn.expand '%:t:r' -- Filename without extension

      if current_file:match '^test_' then
        -- We're in a test file, go to source .cpp
        local source_file = basename:gsub('^test_', '') .. '.cpp'
        vim.cmd('edit ' .. current_path .. '/' .. source_file)
      else
        -- We're in source or header, go to test .cpp
        local test_file = 'test_' .. basename .. '.cpp'
        vim.cmd('edit ' .. current_path .. '/' .. test_file)
      end
    end, { desc = '[T]oggle [T]est file' })
  end,
  keys = {
    { '<leader>th', ':A<CR>', desc = '[T]oggle C++ [H]eader/Source' },
    { '<leader>tv', ':AV<CR>', desc = '[T]oggle in [V]ertical split' },
    { '<leader>ts', ':AS<CR>', desc = '[T]oggle in horizontal [S]plit' },
    -- <leader>tt is defined in config function above
  },
}
