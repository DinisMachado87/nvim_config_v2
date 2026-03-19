local M = {}

-- C++ Class Template Generator
function M.create_class(className, moduleName, isBase)
  local basePath = moduleName and ('srcs/' .. moduleName) or 'srcs'
  local hppFile = basePath .. '/' .. className .. '.hpp'
  local cppFile = basePath .. '/' .. className .. '.cpp'
  local guard = string.upper(className) .. '_HPP'

  local template_dir = vim.fn.stdpath 'config' .. '/templates/cpp-class/'
  local template_type = isBase and 'base' or 'class'

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

  -- Create module directory if specified and doesn't exist
  if moduleName then
    vim.fn.mkdir(basePath, 'p')
  else
    vim.fn.mkdir('srcs', 'p')
  end

  -- Create .hpp file
  local hpp_content = process_template(template_dir .. template_type .. '.hpp', substitutions)
  if hpp_content then
    vim.cmd('edit ' .. hppFile)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, hpp_content)
    vim.cmd 'write'
  end

  -- Create .cpp file
  local cpp_content = process_template(template_dir .. template_type .. '.cpp', substitutions)
  if cpp_content then
    vim.cmd('edit ' .. cppFile)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, cpp_content)
    vim.cmd 'write'
  end

  -- Add to Makefile (with module info if applicable)
  M.add_to_makefile(className .. '.cpp', moduleName)

  print('Created ' .. hppFile .. ', ' .. cppFile .. ', and updated Makefile')

  -- Open both files in vertical split
  vim.cmd('edit ' .. hppFile)
  vim.cmd('vsplit ' .. cppFile)
end

-- Add source file to Makefile
function M.add_to_makefile(filename, moduleName)
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
  local module_exists = false

  -- If module is specified, check if it exists in MODULES variable
  if moduleName then
    local module_dir_var = string.upper(moduleName) .. '_DIR'
    if content:find(module_dir_var, 1, true) then
      module_exists = true
    end
  end

  for i, line in ipairs(lines) do
    table.insert(new_lines, line)

    -- Add module directory variable and to MODULES list if it doesn't exist
    if moduleName and not module_exists and line:match '^PARSER_DIR%s*:=' then
      local module_dir_var = string.upper(moduleName) .. '_DIR'
      table.insert(new_lines, module_dir_var .. ' := ' .. moduleName)
      module_exists = true
    end

    if moduleName and not added and line:match '^MODULES%s*:=' then
      -- Add to MODULES variable if new module
      if not content:find('$(' .. string.upper(moduleName) .. '_DIR)', 1, true) then
        local module_var = '$(' .. string.upper(moduleName) .. '_DIR)'
        -- Remove newline and add module
        new_lines[#new_lines] = new_lines[#new_lines] .. ' ' .. module_var
      end
    end

    -- Find the appropriate SRCS_ variable to add to
    local srcs_pattern = moduleName and ('^SRCS_' .. string.upper(moduleName) .. '%s*:?=') or '^SRCS_MAIN%s*:?='

    if not added and line:match(srcs_pattern) then
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
          table.insert(new_lines, '\t\t\t\t ' .. filename)
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
    end
  end

  -- If we have a new module and haven't added the file yet, create a new SRCS_ variable
  if moduleName and not added then
    -- Find where to insert the new SRCS_ variable (after SRCS_STRVIEW or last SRCS_)
    local insert_pos = nil
    for i, line in ipairs(new_lines) do
      if line:match '^SRCS_' then
        insert_pos = i
      end
    end

    if insert_pos then
      -- Insert new SRCS_ variable
      table.insert(new_lines, insert_pos + 1, '')
      table.insert(new_lines, insert_pos + 2, 'SRCS_' .. string.upper(moduleName) .. ' := ' .. filename)

      -- Update SRCS_CORE to include new module
      for i = insert_pos + 3, #new_lines do
        if new_lines[i]:match '^SRCS_CORE%s*:=' then
          -- Find the end of SRCS_CORE definition
          local j = i
          while j <= #new_lines and (new_lines[j]:match '\\%s*$' or j == i) do
            j = j + 1
          end
          -- Insert new line before the end
          local module_var = string.upper(moduleName)
          local srcs_line = '\t\t\t\t $(SRCS_' .. module_var .. ':%.cpp=$(' .. module_var .. '_DIR)/%.cpp) \\'
          table.insert(new_lines, j, srcs_line)
          break
        end
      end
      added = true
    end
  end

  if not added then
    print 'Warning: Could not find appropriate SRCS variable in Makefile'
    print('Please add manually: ' .. filename)
    return
  end

  -- Write back to Makefile
  file = io.open(makefile, 'w')
  if file then
    file:write(table.concat(new_lines, '\n'))
    file:close()
    print('Added ' .. filename .. ' to Makefile' .. (moduleName and (' in module ' .. moduleName) or ''))
  else
    print 'Error: Could not write to Makefile'
  end
end

-- Extract method prototype and add to header
function M.copy_method_to_header()
  local current_line = vim.api.nvim_get_current_line()

  -- Extract until '{'
  local prototype = current_line:match '(.-)%s*{'
  if not prototype then
    print 'Error: No method signature found on current line'
    return
  end

  -- Remove class qualifier (e.g., "ClassName::")
  prototype = prototype:gsub('%w+::', '')

  -- Trim whitespace and add semicolon
  prototype = prototype:match '^%s*(.-)%s*$' .. ';'

  -- Get current cpp file name to determine header file
  local cpp_file = vim.api.nvim_buf_get_name(0)
  local header_file = cpp_file:gsub('%.cpp$', '.hpp')

  -- Find and open header file
  local header_buf = nil
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(buf) == header_file then
      header_buf = buf
      break
    end
  end

  if not header_buf then
    vim.cmd('edit ' .. header_file)
    header_buf = vim.api.nvim_get_current_buf()
  end

  -- Find "// Methods" section
  local lines = vim.api.nvim_buf_get_lines(header_buf, 0, -1, false)
  local insert_line = nil

  for i, line in ipairs(lines) do
    if line:match '// Methods' then
      insert_line = i
      break
    end
  end

  if not insert_line then
    print 'Error: Could not find "// Methods" section in header'
    return
  end

  -- Insert prototype with proper indentation
  vim.api.nvim_buf_set_lines(header_buf, insert_line, insert_line, false, { '\t' .. prototype })
  print 'Added method prototype to header'
end

-- Setup function to register commands and keybindings
function M.setup()
  -- Create the command for regular class (supports optional module name)
  vim.api.nvim_create_user_command('CreateClass', function(opts)
    local args = vim.split(opts.args, '%s+')
    local className = args[1]
    local moduleName = args[2]
    M.create_class(className, moduleName, false)
  end, { nargs = '+' })

  -- Create the command for base class (supports optional module name)
  vim.api.nvim_create_user_command('CreateBase', function(opts)
    local args = vim.split(opts.args, '%s+')
    local className = args[1]
    local moduleName = args[2]
    M.create_class(className, moduleName, true)
  end, { nargs = '+' })

  -- Keybinding for regular class
  vim.keymap.set('n', '<leader>cc', function()
    vim.ui.input({ prompt = 'Class name (optionally: ClassName ModuleName): ' }, function(input)
      if input then
        local args = vim.split(input, '%s+')
        M.create_class(args[1], args[2], false)
      end
    end)
  end, { desc = 'Create C++ Class' })

  -- Keybinding for base class
  vim.keymap.set('n', '<leader>cb', function()
    vim.ui.input({ prompt = 'Base class name (optionally: ClassName ModuleName): ' }, function(input)
      if input then
        local args = vim.split(input, '%s+')
        M.create_class(args[1], args[2], true)
      end
    end)
  end, { desc = 'Create C++ Base Class' })

  -- Keybinding to copy method to header
  vim.keymap.set('n', '<leader>cm', M.copy_method_to_header, { desc = 'Copy method to header' })
end

return M
