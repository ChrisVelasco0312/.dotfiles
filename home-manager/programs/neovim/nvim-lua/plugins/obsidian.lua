require('obsidian').setup({
  workspaces = {
    {
      name = "vaults",
      path = "~/Desktop/vaults",
    }
  },
  follow_url_func = function(url)
    vim.fn.jobstart({ "xdg-open", url })
  end
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.bo.textwidth = 80
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
    vim.bo.softtabstop = 2
    vim.bo.formatoptions = vim.bo.formatoptions .. "t"
  end,
})

-- Function to rearrange selected lines
local function rearrange_lines(opts)
  local char_limit = tonumber(opts.args) or 80

  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

  local text = table.concat(lines, " ")

  local words = vim.split(text, " ")

  local result = {}
  local current_line = ""

  for _, word in ipairs(words) do
    if #current_line + #word + 1 <= char_limit then
      if current_line ~= "" then
        current_line = current_line .. " " .. word
      else
        current_line = word
      end
    else
      if current_line ~= "" then
        table.insert(result, current_line)
      end
      current_line = word
    end
  end

  if current_line ~= "" then
    table.insert(result, current_line)
  end

  local i = 1
  while i < #result do
    if #vim.split(result[i], " ") == 1 then
      result[i] = result[i] .. " " .. result[i + 1]
      table.remove(result, i + 1)
    else
      i = i + 1
    end
  end

  vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, result)
end

vim.api.nvim_create_user_command("RearrangeLines", rearrange_lines, {
  range = true, 
  nargs = "?", 
  desc = "Rearrange selected lines to fit within a character limit, ensuring no single word is left alone.",
})
