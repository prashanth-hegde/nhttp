local api = vim.api
local buf, win
local windows = require("windows")
local parser = require("intelliparser")

local function parse_response(resp)
  if resp == nil then return end
  local status = 0
  local start = false
  local content_type, content_length, content = "", "", ""
  for k, v in ipairs(resp) do
    if k == 1 then
      status = tonumber(v:match(" (%d+)%s"))
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
  local time_elapsed = os.clock() - start
  status, content_type, content_length, content = parse_response(resp)
  local size = "unknown"
  if #content_length > 0 then size = content_length end
  status_txt = string.format("status=%d | time=%.3f s | size=%s \n", status, time_elapsed, size)
  api.nvim_out_write(status_txt)

  windows.println(type(status))
  local post_process_cmd = api.nvim_get_var("nhttp_cmd")
  local processed_output = ""
  if status <= 206 and #post_process_cmd > 0 then
    local pp_cmd = string.gsub(post_process_cmd, '?', string.format("'%s'", content))
    processed_output = processed_output .. vim.fn.system(pp_cmd)
    windows.print_response(processed_output)
  else
    windows.print_response(content)
  end
end

local function show_command()
  local cmd = parser.get_curl_command()
  windows.print_response(cmd)
end

return {
    execute_command             = execute_command,
    show_command                = show_command,
}
