local api = vim.api
local windows = require("nhttp_windows")
local parser = require("intelliparser")

local function parse_response(resp)
  if resp == nil then return end
  local status = 0
  local start = false
  local content_type, content_length, content = "", "", ""
  for k, v in ipairs(resp) do
    if k == 1 then
      status = tonumber(v:match(" (%d+)%s")) or 500
      if status > 206 then
        start = true
        content = content .. v
      end
    elseif not start and v:lower():match("content%-type") then
      content_type = string.match(v, "%a+$")
    elseif not start and v:lower():match("content%-length") then
      content_length = string.match(v, "%d+")
    elseif not start and v:gsub("%s+", "") == "" then
      start = true
    elseif start then
      content = content .. v
    end
  end

  return status, content_type, content_length, content
end

local function execute_command()
  local cmd = parser.get_curl_command()
  local start = os.clock()
  local resp = vim.fn.systemlist(cmd)
  local time_elapsed = (os.clock() - start) * 100
  local status, content_type, content_length, content = parse_response(resp)
  local size = "unknown"
  if content_length ~= nil and #content_length > 0 then size = content_length end
  local status_txt = string.format("status=%d | time=%.3f s | size=%s \n", status, time_elapsed, size)
  api.nvim_out_write(status_txt)

  local post_process_cmd = api.nvim_get_var("nhttp_cmd")
  if status <= 206 and #(post_process_cmd:gsub("%s+", "")) > 0 then
    local pp_cmd = post_process_cmd:gsub('?', string.format("'%s'", content))
    windows.print_out(vim.fn.systemlist(pp_cmd))
  else
    windows.print_out(content)
  end
end

local function show_command()
  local cmd = parser.get_curl_command()
  windows.print_out(cmd)
end

local function copy_to_clipboard()
  local cmd = parser.get_curl_command()
  vim.fn.setreg('*', cmd)
end

return {
    execute_command             = execute_command,
    show_command                = show_command,
    copy_to_clipboard           = copy_to_clipboard,
}
