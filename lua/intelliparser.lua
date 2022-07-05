local api = vim.api
local json = require("nhttp_json")
local util = require("nhttp_utils")

local function get_type()
  return api.nvim_buf_get_option(0, "filetype")
end

local function extract_relevant_lines()
  local linenum = api.nvim_win_get_cursor(0)[1]
  local start_line, end_line = linenum, linenum
  -- find start of block
  repeat
    local currline = api.nvim_buf_get_lines(0, linenum-1, linenum, false)[1]
    linenum = linenum - 1
  until linenum == 0 or currline == nil or string.find(currline, "###") ~= nil
  start_line = linenum + 1
  -- find end of block
  linenum = end_line
  repeat
    local currline = api.nvim_buf_get_lines(0, linenum-1, linenum, false)[1]
    linenum = linenum + 1
  until linenum == api.nvim_buf_line_count(0) or currline == nil or string.find(currline, "###") ~= nil
  end_line = linenum - 2

  local buflines = api.nvim_buf_get_lines(0, start_line, end_line, false)
  return buflines
end

local function create_usable_url(block)
  if block == nil then return "" end
  local url = ""
  local headers = {}
  for k, v in next, block, nil do
    if string.find(v, "#") == nil and string.find(v, ":") == nil then
      url = url .. v
    elseif string.find(v, "#") == nil and string.find(v, ":") ~= nil then
      table.insert(headers, v)
    end
  end

  local header_str = ""
  for k, v in next, headers, nil do
    header_str = header_str .. string.format(' -H "%s"', v)
  end

  url = string.gsub(url, "%s+", "")
  return url .. header_str
end

local function lines_from(file)
  local function file_exists(file)
    local f = io.open(file, "rb")
	if f then f:close() end
  	return f ~= nil
  end
  if not file_exists(file) then return {} end
  local lines = {}
  for line in io.lines(file) do
    lines[#lines + 1] = line
  end
  return lines
end

local function hydrate_config(url)
  local function get_config()
    local working_file = api.nvim_buf_get_name(0)
    local path = string.gsub(working_file, "(.*/)(.*)", "%1")
    local conf_file =  path .. "http-client.env.json"
    if conf_file == nil then return nil end

    local currenv = util.get_opt("nhttp_env")
    local conf_lines = lines_from(conf_file)
    local conf = json.parse_table(conf_lines)
    if conf == nil then
      api.nvim_out_write("No config found. Ensure you have http-client.env.json defined in directory\n")
      return nil
    end
    return conf[currenv]
  end

  if string.match(url, "{{%S+}}") == nil then return url end
  local conf = get_config()
  if conf == nil then return end

  local var = string.match(url, "{{%S+}}")
  while var ~= nil do
    local v = string.match(var, "[0-9a-zA-Z_-]+")
    if conf[v] == nil then
      api.nvim_out_write(string.format("No config found for %s, aborting.\n", var))
      return
    end
    url = string.gsub(url, "%b{}", conf[v], 1)
    var = string.match(url, "{{%S+}}")
  end
  return url
end

local function get_curl_command()
  local currfiletype, err = pcall(get_type)
  if currfiletype == false or (get_type() ~= "http" and get_type() ~= "conf") then
    api.nvim_out_write("File is not http, cannot execute. :set ft=http and try again\n")
    return
  end

  local rel_lines = extract_relevant_lines()
  local url = create_usable_url(rel_lines)
  local sanitized_url = hydrate_config(url):gsub("http", " http"):gsub("(http%S+)", '"%1"')
  local url_command = "curl -s -i -X " .. sanitized_url
  return url_command
end

return {
  get_curl_command = get_curl_command
}

