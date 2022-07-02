local api = vim.api

local out_buf_name = "output"
local function get_out_buf()
  for i, b in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_loaded(b) and api.nvim_buf_get_name(b) == out_buf_name then
      return b
    end
  end
  return nil
end

local function window_handler()
  -- get window handler configurations
  output_switch = api.nvim_get_var("nhttp_switch_to_output_window")
  out_buf_present, err = pcall(function() api.nvim_get_var("nhttp_is_output_buf_present") end)

  -- output window
  req_window = api.nvim_get_current_win()

  --if get_out_buf() == nil then
  --  api.nvim_command("vsplit output")
  --  api.nvim_command("set ft=json")
  --  api.nvim_command("set wrap")
  --end
  if not out_buf_present then
    api.nvim_command("vsplit output")
    resp_window = api.nvim_get_current_win()
    api.nvim_command("set ft=json")
    api.nvim_command("set wrap")
    api.nvim_set_var("nhttp_is_output_buf_present", "true")
  end

  return req_window, resp_window
  --return req_window, get_out_buf()
end

local function print_response(resp)
  if resp == nil then return end
  req_window, resp_window = window_handler()
  api.nvim_set_current_win(resp_window)
  api.nvim_command("%d")
  api.nvim_paste(resp, true, -1)

  if output_switch == 'true' then
    api.nvim_set_current_win(resp_window)
  else
    api.nvim_set_current_win(req_window)
  end
end

local function println(resp)
  if resp == nil then return end
  req_window, resp_window = window_handler()
  api.nvim_set_current_win(resp_window)
  api.nvim_paste(resp.."\n", true, -1)
end

local function print_table(tab)
  if tab == nil then return end
  txt = ""
  for i, x in ipairs(tab) do
    txt = txt .. x
  end
  print_response(txt)
end

return {
  print_response = print_response,
  println        = println,
}
