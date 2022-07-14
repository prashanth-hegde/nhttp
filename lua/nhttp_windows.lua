local api = vim.api
local util = require("nhttp_utils")

local out_buf_name = "nhttp_output"

local function get_out_win()
  local outwin
  local currwin = api.nvim_get_current_win()
  for _, w in ipairs(api.nvim_tabpage_list_wins(0)) do
    local currbuf = api.nvim_win_get_buf(w)
    local bufname = api.nvim_buf_get_name(currbuf)
    if bufname:match(out_buf_name) ~= nil then outwin = w end
  end

  if outwin == nil then
    -- outwin not present, create one
    local split = util.get_opt("jpath_split")
    local cmd = "belowright vsplit "
    if split == "horizontal" then cmd = "belowright split " end
    api.nvim_command(cmd..out_buf_name)
    outwin = api.nvim_get_current_win()
    api.nvim_command("set ft=json")
    api.nvim_command("set nowrap")
    api.nvim_set_current_win(currwin)
  end

  return outwin
end

local function print_out(output)
  if output == nil or output == "" then return end
  local currwin = api.nvim_get_current_win()
  local switch = (util.get_opt("nhttp_switch_to_output_window") == "true")

  local outwin = get_out_win()
  api.nvim_set_current_win(outwin)
  api.nvim_command("%d")
  if type(output) == "table" then
    api.nvim_put(output, "l", true, false)
  elseif type(output) == "string" then
    api.nvim_command("set wrap")
    api.nvim_paste(output, true, -1)
    api.nvim_win_set_cursor(0, {1, 0})
  end

  if not switch then api.nvim_set_current_win(currwin) end
end


return {
  print_out      = print_out,
}
