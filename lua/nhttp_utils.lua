local api = vim.api

local function println(output)
  if output == nil or output == "" then return end
  local txt = ""
  if type(output) == "table" then
    for _, v in ipairs(table) do
      if v ~= nil then txt = txt .. v end
    end
  elseif type(output) == "string" then
    txt = output
  end

  api.nvim_out_write(txt..'\n')
end

local function get_opt(opt)
  local defaults = {
    ["nhttp_switch_to_output_window"]   = "false",
    ["nhttp_split"]                     = "vertical",
    ["nhttp_env"]                       = "prod",
    ["nhttp_cmd"]                       = "",
    -- ["nhttp_config_file"]             = "http-client.env.json"
  }
  local o, err = pcall(function() api.nvim_get_var(opt) end)
  if not o then
    o = defaults[opt]
  else
    o = api.nvim_get_var(opt)
  end
  -- todo: this used to be tostring(0) and recently changed to remove tostring()
  -- if there are issues with the plugin, check this
  return o
end

return {
  get_opt           = get_opt,
  println           = println,
}
