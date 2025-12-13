local M = {}

-- C++ Class Template Generator
function M.create_class(className)
  local hppFile = 'srcs/' .. className .. '.hpp'
  local cppFile = 'srcs/' .. className .. '.cpp'
  local guard = string.upper(className) .. '_HPP'

  local template_dir = vim.fn.stdpath 'config' .. '/templates/cpp-class/'

  -- Helper function to read and substitute template
  local function process_template(template_file, substitutions)
    local file = io.open(template_file, 'r')
    if not file then
      print('Error: Template file not found: ' .. template_file)
      return nil
    end

    local content = file:read '*all'
    file:close()

    -- Perform substitutions
    for key, value in pairs(substitutions) do
      content = content:gsub('{{' .. key .. '}}', value)
    end

    return vim.split(content, '\n')
  end

  local substitutions = {
    CLASS_NAME = className,
    GUARD = guard,
  }

  -- Create srcs directory if it doesn't exist
  vim.fn.mkdir('srcs', 'p')

  -- Create .hpp file
  local hpp_content = process_template(template_dir .. 'class.hpp', substitutions)
  if hpp_content then
    vim.cmd('edit ' .. hppFile)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, hpp_content)
    vim.cmd 'write'
  end

  -- Create .cpp file
  local cpp_content = process_template(template_dir .. 'class.cpp', substitutions)
  if cpp_content then
    vim.cmd('edit ' .. cppFile)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, cpp_content)
    vim.cmd 'write'
  end

  -- Add to Makefile
  M.add_to_makefile(className .. '.cpp')

  print('Created ' .. hppFile .. ', ' .. cppFile .. ', and updated Makefile')

  -- Open both files in vertical split
  vim.cmd('edit ' .. hppFile) -- Open .hpp in current window
  vim.cmd('vsplit ' .. cppFile) -- Open .cpp in vertical split
end

-- Add source file to Makefile
function M.add_to_makefile(filename)
  local makefile = 'Makefile'

  local file = io.open(makefile, 'r')
  if not file then
    print 'Warning: Makefile not found in root directory'
    return
  end

  local content = file:read '*all'
  file:close()

  -- Check if file is already in Makefile
  if content:find(filename, 1, true) then
    print 'File already exists in Makefile'
    return
  end

  local lines = vim.split(content, '\n')
  local new_lines = {}
  local added = false

  for i, line in ipairs(lines) do
    -- Check if this is a SRCS line
    if line:match '^SRCS%s*:?=' then
      -- Start of SRCS, add it
      table.insert(new_lines, line)

      -- Now find the last line in this multi-line definition
      local j = i + 1
      while j <= #lines do
        local next_line = lines[j]

        -- If this line ends with backslash, it continues
        if next_line:match '\\%s*$' then
          table.insert(new_lines, next_line)
          j = j + 1
        else
          -- This is the LAST line of SRCS (no backslash)
          -- Add backslash to it and add our new file
          local trimmed = next_line:gsub('%s*$', '')
          table.insert(new_lines, trimmed .. ' \\')
          table.insert(new_lines, '\t\t\t   ' .. filename)
          added = true

          -- Copy remaining lines
          for k = j + 1, #lines do
            table.insert(new_lines, lines[k])
          end
          break
        end
      end

      if added then
        break
      end
    else
      if not added then
        table.insert(new_lines, line)
      end
    end
  end

  if not added then
    print 'Warning: Could not find SRCS variable in Makefile'
    print('Please add manually: ' .. filename)
    return
  end

  -- Write back to Makefile
  file = io.open(makefile, 'w')
  if file then
    file:write(table.concat(new_lines, '\n'))
    file:close()
    print('Added ' .. filename .. ' to Makefile')
  else
    print 'Error: Could not write to Makefile'
  end
end

-- Setup function to register commands and keybindings
function M.setup()
  -- Create the command
  vim.api.nvim_create_user_command('CreateClass', function(opts)
    M.create_class(opts.args)
  end, { nargs = 1 })

  -- Optional: Keybinding
  vim.keymap.set('n', '<leader>cc', function()
    vim.ui.input({ prompt = 'Class name: ' }, function(input)
      if input then
        M.create_class(input)
      end
    end)
  end, { desc = 'Create C++ Class' })
end

return M
