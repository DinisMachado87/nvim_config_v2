-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('t', '<C-w>w', '<C-\\><C-n><C-w>w', { noremap = true })

vim.keymap.set('i', 'kj', '<Esc>', { desc = 'Map esc to kj' })
vim.keymap.set('v', 'kj', '<Esc>', { desc = 'Map esc to kj' })
vim.keymap.set('i', 'jk', '<Esc>', { desc = 'Map esc to kj' })
vim.keymap.set('v', 'jk', '<Esc>', { desc = 'Map esc to kj' })

-- TIP: Disable arrow keys in normal mode
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

vim.keymap.set('n', '<leader>cpp', ':!cp -r ~/.config/nvim/templates/cpp-init/* .<CR>:e srcs/main.cpp', { desc = 'Init cpp repo' })
vim.keymap.set('n', '<leader>hd', function()
  local filename = vim.fn.expand('%:t'):upper():gsub('%.', '_')
  vim.api.nvim_input('ggO<Esc>' .. 'O#ifndef ' .. filename .. '<Esc>' .. 'o# define ' .. filename .. '<Esc>' .. 'Go<Esc>' .. 'o#endif<Esc>' .. '3gg')
end, { desc = 'Add header guards' })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.keymap.set('n', '<leader>dy', function()
  local diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line '.' - 1 })
  if #diagnostics > 0 then
    local messages = {}
    for _, diag in ipairs(diagnostics) do
      table.insert(messages, diag.message)
    end
    local text = table.concat(messages, '\n')
    vim.fn.setreg('+', text)
    print 'Diagnostic copied to clipboard'
  else
    print 'No diagnostics on this line'
  end
end, { desc = 'Yank diagnostic to clipboard' })

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'cpp', 'c' },
  callback = function(args)
    local bufnr = args.buf

    vim.keymap.set('n', '<leader>u', function()
      local word = vim.fn.expand '<cWORD>'
      local namespace, identifier = word:match '([%w_]+)::([%w_]+)'

      if not namespace or not identifier then
        vim.notify('Not on a namespaced identifier', vim.log.levels.WARN)
        return
      end

      local using_line = 'using ' .. namespace .. '::' .. identifier .. ';'

      -- Check if already exists
      local found = false
      for i = 1, vim.fn.line '$' do
        if vim.fn.getline(i) == using_line then
          found = true
          break
        end
      end

      if not found then
        local insert_line = 1
        local has_using = false

        for i = 1, vim.fn.line '$' do
          local line = vim.fn.getline(i)
          if line:match '^using' then
            has_using = true
          end
          if line:match '^#include' or line:match '^using' then
            insert_line = i + 1
          elseif line:match '%S' and not line:match '^//' then
            break
          end
        end

        -- ADD BLANK LINE if inserting after includes and no using declarations exist
        local prev_line = vim.fn.getline(insert_line - 1)
        if prev_line:match '^#include' and not has_using then
          vim.fn.append(insert_line - 1, '')
          vim.fn.append(insert_line, using_line)
        else
          vim.fn.append(insert_line - 1, using_line)
        end

        vim.notify('Added: ' .. using_line, vim.log.levels.INFO)
      else
        vim.notify('Already exists: ' .. using_line, vim.log.levels.INFO)
      end

      -- Remove namespace prefix on current line
      local current_line = vim.fn.getline '.'
      local new_line = current_line:gsub(namespace .. '::', '')
      vim.fn.setline('.', new_line)
    end, {
      buffer = bufnr,
      desc = 'Add [U]sing declaration and remove prefix',
    })
  end,
})

-- vim: ts=2 sts=2 sw=2 et
