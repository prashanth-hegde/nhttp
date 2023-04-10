local api = vim.api
local json = require("nhttp_json")
local util = require("nhttp_utils")

local function get_type()
  return api.nvim_buf_get_option(0, "filetype")
end


-- function that only extracts relevant lines from the current buffer
-- takes into account the cursor position
local function extract_relevant_lines()
  local linenum = api.nvim_win_get_cursor(0)[1]
  local linebreak = "###"
  local start_line, end_line = linenum, linenum
  -- find start of block
  repeat
    local currline = api.nvim_buf_get_lines(0, linenum-1, linenum, false)[1]
    linenum = linenum - 1
  until linenum == 0 or currline == nil or string.find(currline, linebreak) ~= nil
  start_line = linenum + 1
  -- find end of block
  linenum = end_line
  repeat
    local currline = api.nvim_buf_get_lines(0, linenum-1, linenum, false)[1]
    linenum = linenum + 1
  until linenum == api.nvim_buf_line_count(0) or currline == nil or string.find(currline, linebreak) ~= nil
  end_line = linenum - 2

  local buflines = api.nvim_buf_get_lines(0, start_line, end_line, false)
  return buflines
end

local function create_usable_url(block)
  if block == nil then return "" end
  local url = ""
  local headers = {}
  for _, v in next, block, nil do
    if string.find(v, "#") == nil and (string.find(v, ":") == nil or string.match(v, "http") ~= nil) then
      url = url .. v
    elseif string.find(v, "#") == nil and string.find(v, ":") ~= nil  then
      table.insert(headers, v)
    end
  end

  local header_str = ""
  for _, v in next, headers, nil do
    header_str = header_str .. string.format(' -H "%s"', v)
  end

  url = string.gsub(url, "%s+", "")
  return url .. header_str
end

local function lines_from(file)
  local function file_exists(fi)
    local f = io.open(fi, "rb")
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
  -- nhttp allows to override global defaults inside the file itself
  -- This can be done by specifying the global variable name as a comment
  -- within the file. Note that these need to be specified before the first
  -- separator ###
  -- Regardless of the cursor position, the environment variables are always
  -- expected at the beginning of the file before ###
  local function check_for_configs_in_file()
    -- helper function that takes in a line, identifies nhttp_ fields in them
    -- and extracts the key and value separated by "=" and puts stuff on a specified map
    local function extract_variables_to_map(line, map)
      local separator = "="
      local tokens = {}
      for token in line:gmatch("([^"..separator.."]+)") do
        token = token:gsub("[%s#\"\']+", "")  -- trim spaces, quotes, comments
        table.insert(tokens, token)
      end
      if #tokens == 2 then
        -- only add tokens to the map if there are key and value, else skip
        map[tokens[1]] = tokens[2]
      end
    end

    local linenum = 0
    local local_vars = {}
    repeat
      local currline = api.nvim_buf_get_lines(0, linenum, linenum+1, false)[1]
      if string.find(currline, "nhttp_") ~= nil then
        extract_variables_to_map(currline, local_vars)
      end
      linenum = linenum + 1
    until currline == nil or string.find(currline, "###") ~= nil

    return local_vars
  end

  -- helper function to get global configuration. First checks for
  -- the default file `http-client.env.json` to be present in the same directory
  -- as the file that is running. next checks if it is defined in global variables
  -- and lastly checks if it is defined in the file beginning. If found in multiple
  -- places, the order of precedence is
  -- 1. file path declared at the beginning with nhttp_config_file parameter
  -- 2. global environment variable
  -- 3. local file http-client.env.json present in the same directory as the .http file
  local function get_config_file(local_vars)
    local cfg_var = "nhttp_config_file"
    local config_file_path = ""
    local from_opt = util.get_opt(cfg_var)
    if local_vars[cfg_var] ~= nil then
      config_file_path = local_vars[cfg_var]
    elseif from_opt ~= nil then
      config_file_path = util.get_opt(cfg_var)
    else
      config_file_path = "http-client.env.json"
    end

    if config_file_path ~= nil and config_file_path:sub(1, 1) ~= "/" then
      -- the provided config is not an absolute path, use it with relative to file path
      config_file_path = string.gsub(api.nvim_buf_get_name(0), "(.*/)(.*)", "%1") .. config_file_path
    end

    return config_file_path
  end

  local function get_config(local_vars)
    local conf_file =  get_config_file(local_vars)
    local env_cfg = "nhttp_env"
    local currenv = util.get_opt(env_cfg)
    local conf_lines = lines_from(conf_file)
    local conf = json.parse_table(conf_lines)
    if conf == nil then
      -- if config file is not the default, check global variables or in the file
      return nil
    end
    if local_vars[env_cfg] ~= nil then
      currenv = local_vars[env_cfg]
    end
    return conf[currenv]
  end

  if string.match(url, "{{%S+}}") == nil then return url end
  local local_vars = check_for_configs_in_file()
  local conf = get_config(local_vars)
  if conf == nil then return end

  local var = string.match(url, "{{%S+}}")
  while var ~= nil do
    local v = string.match(var, "[0-9a-zA-Z_-]+")
    if conf[v] == nil then
      api.nvim_out_write(string.format("No config found for %s, aborting.\n", var))
      return
    end
    -- check if this config is available in the local_vars map. If it is, use that
    -- else fall back to the config file
    url = string.gsub(url, "%b{}", conf[v], 1)
    var = string.match(url, "{{%S+}}")
  end
  return url
end

local function get_curl_command()
  local currfiletype, _ = pcall(get_type)
  if currfiletype == false or (get_type() ~= "http" and get_type() ~= "conf") then
    api.nvim_out_write("File is not http, cannot execute. :set ft=http and try again\n")
    return
  end

  local rel_lines = extract_relevant_lines()
  local url = create_usable_url(rel_lines)
  local hydrated_url = hydrate_config(url)
  if hydrated_url == nil then
      api.nvim_out_write("either config file not found or is not configured, in order\n")
      api.nvim_out_write("1. as a comment at the top of the file nhttp_config_file = path\n")
      api.nvim_out_write("2. as global variable let g:nhttp_config_file = 'filename.json' \n")
      api.nvim_out_write("3. http-client.env.json in the same directory as this file\n")
      return nil
  end
  local sanitized_url = hydrate_config(url):gsub("http", " http"):gsub("(http%S+)", '"%1"')
  local url_command = "curl -s -i -X " .. sanitized_url
  return url_command
end

return {
  get_curl_command = get_curl_command
}

