require('obsidian').setup({
  workspaces = {
    {
      name = "vaults",
      path = "~/Desktop/vaults",
    }
  },
  follow_url_func = function(url)
    vim.fn.jobstart({"xdg-open", url})
  end
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.bo.textwidth = 80
    vim.bo.formatoptions = vim.bo.formatoptions .. "t"
  end,
})

-- Function to rearrange selected lines
local function rearrange_lines(opts)
  -- Get the character limit from the command arguments (default to 80 if not provided)
  local char_limit = tonumber(opts.args) or 80

  -- Get the start and end lines of the visual selection
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")

  -- Get the selected lines as a list
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

  -- Join the lines into a single string
  local text = table.concat(lines, " ")

  -- Split the text into words
  local words = vim.split(text, " ")

  -- Initialize variables
  local result = {}
  local current_line = ""

  -- Build lines while respecting the character limit
  for _, word in ipairs(words) do
    if #current_line + #word + 1 <= char_limit then
      -- Add the word to the current line
      if current_line ~= "" then
        current_line = current_line .. " " .. word
      else
        current_line = word
      end
    else
      -- Finalize the current line and start a new one
      if current_line ~= "" then
        table.insert(result, current_line)
      end
      current_line = word
    end
  end

  -- Add the last line if it's not empty
  if current_line ~= "" then
    table.insert(result, current_line)
  end

  -- Ensure no single word is left alone on a line
  local i = 1
  while i < #result do
    if #vim.split(result[i], " ") == 1 then
      -- Merge the single-word line with the next line
      result[i] = result[i] .. " " .. result[i + 1]
      table.remove(result, i + 1)
    else
      i = i + 1
    end
  end

  -- Replace the selected lines with the rearranged lines
  vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, result)
end

-- Define a custom command to call the function
vim.api.nvim_create_user_command("RearrangeLines", rearrange_lines, {
  range = true, -- Allows the command to work on selected lines
  nargs = "?",  -- Accepts an optional argument (character limit)
  desc = "Rearrange selected lines to fit within a character limit, ensuring no single word is left alone.",
})
