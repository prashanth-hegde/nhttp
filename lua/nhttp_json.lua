
local function parse(text)
  if text == nil then return nil end
  L = "return " .. text:gsub('("[^"]-"):','[%1]=')
  T = load(L)()
  return T
end

local function parse_table(tab)
  if tab == nil or tab == "" then return nil end
  local text = ""
  for k, v in ipairs(tab) do
    text = text .. v
  end
  return parse(text)
end

local function prettify(tab, depth)
  if tab == nil then return "" end
  depth = depth or 1
  local prettified = ""

  -- helpers
  function indent(d)
    return string.rep(" ", d*2)
  end
  function get_type()
    local typ = "string"
    if (type(tab) == "table" and #tab > 0) then
      typ = "array"
    elseif type(tab) == "table" then
      typ = "object"
    elseif type(tab) == "number" then
      typ = "number"
    elseif type(tab) == "boolean" then
      typ = "boolean"
    else
      typ = "string"
    end
    return typ
  end
  -- end helpers

  local typ = get_type()
  if typ == "object" then
    -- {\n <indent> key: <children> \n <indent> },
    prettified = prettified .. '{\n'
    for k, v in pairs(tab) do
      prettified = prettified .. string.format('%s"%s": %s\n', indent(depth), k, prettify(v, depth+1))
    end
    -- :gsub('",(%s+})', '"%1')
    prettified = prettified .. indent(depth-1) .. '}'
  elseif typ == "array" then
    prettified = prettified .. '[\n'
    for k, v in ipairs(tab) do
      prettified = prettified .. string.format('%s%s\n', indent(depth), prettify(v, depth+1))
    end
    prettified = prettified .. indent(depth-1) .. ']'
  elseif typ == "string" then
    prettified = prettified .. string.format(' "%s",', tab)
  end

  return prettified:gsub('",(%s+[}%]])', '"%1') .. ''
end

------------------- return object
return {
  parse         = parse,
  parse_table   = parse_table,
}
