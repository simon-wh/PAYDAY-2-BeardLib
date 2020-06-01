-----------------------------------------------------------------------------
-- JSON4Lua: JSON encoding / decoding support for the Lua language.
-- json Module.
-- Author: Craig Mason-Jones
-- Homepage: http://json.luaforge.net/
-- Version: 0.9.50
-- This module is released under the MIT License (MIT).
-- Please see LICENCE.txt for details.
-- Modified by: GREAT BIG BUSHY BEARD
-----------------------------------------------------------------------------


local encodeString
local isArray
local isEncodable

local function init_token_table (tt)
    local struct = {}
    local value
    function struct:link(other_tt)
        value = other_tt
        return struct
    end
    function struct:to(chars)
        for i=1,#chars do
            tt[chars:byte(i)] = value
        end
        return struct
    end
    return function (name)
        tt.name = name
        return struct
    end
end

local function get_tabs(i)
    local str = ""
    for i = 1, i do
        str = str .. "\t"
    end
    return str
end

--- Encodes an arbitrary Lua object / variable.
-- @param v The Lua object / variable to be JSON encoded.
-- @return String containing the JSON encoding in internal Lua string format (i.e. not unicode)
function json.custom_encode (v, format, tabs)
    tabs = tabs or 0

  -- Handle nil values
  if v==nil then
    return "null"
  end

  local vtype = CoreClass.type_name(v)

  -- Handle strings
  if vtype=='string' or vtype=='Vector3' or vtype=='Rotation' or vtype=='Color' or vtype=='callback' then
    return '"' .. encodeString(v) .. '"'	    -- Need to handle encoding in string
  end

  -- Handle booleans
  if vtype=='number' or vtype=='boolean' then
    return tostring(v)
  end

  -- Handle tables
  if vtype=='table' then
    local rval = {}
    -- Consider arrays separately
    local bArray, maxCount = isArray(v)
    if bArray then
      for i = 1,maxCount do
        table.insert(rval, json.custom_encode(v[i], format, tabs + 1))
      end
    else	-- An object, not an array
      for i,j in pairs(v) do
        if isEncodable(i) and isEncodable(j) then
          table.insert(rval, '"' .. encodeString(i) .. '":' .. json.custom_encode(j, tabs + 1))
        end
      end
    end

    local length = 0
    for _, _ in pairs(rval) do
        length = length + 1
    end

    if bArray then
        if length > 0 then
            return '[' .. (format and '\n' or '') .. get_tabs(tabs + 1) .. table.concat(rval,',' .. (format and '\n' or '') .. get_tabs(tabs + 1)) .. (format and '\n' or '') .. get_tabs(tabs) .. ']'
        else
            return '{}'
        end
    else
        if length > 0 then
            return '{' .. (format and '\n' or '') .. get_tabs(tabs + 1) .. table.concat(rval,',' .. (format and '\n' or '') .. get_tabs(tabs + 1)) .. (format and '\n' or '') .. get_tabs(tabs) .. '}'
        else
            return '{}'
        end
    end
  end

  -- Handle null values
  if vtype=='function' and v==nil then
    return 'null'
  end

  assert(false,'encode attempt to encode unsupported type ' .. vtype .. ':' .. base.tostring(v))
end

--- Encodes a string to be JSON-compatible.
-- This just involves back-quoting inverted commas, back-quotes and newlines, I think ;-)
-- @param s The string to return as a JSON encoded (i.e. backquoted string)
-- @return The string appropriately escaped.
local qrep = {["\\"]="\\\\", ['"']='\\"',['\n']='\\n',['\t']='\\t'}
function encodeString(s)
    if CoreClass.type_name(s) == "Color" then
        return string.format("Color(%s, %s, %s, %s)", s.a, s.r, s.g, s.b)
    end

  return tostring(s):gsub('["\\\n\t]',qrep)
end

-- Determines whether the given Lua type is an array or a table / dictionary.
-- We consider any table an array if it has indexes 1..n for its n items, and no
-- other data in the table.
-- I think this method is currently a little 'flaky', but can't think of a good way around it yet...
-- @param t The table to evaluate as an array
-- @return boolean, number True if the table can be represented as an array, false otherwise. If true,
-- the second returned value is the maximum
-- number of indexed elements in the array.
function isArray(t)
  -- Next we count all the elements, ensuring that any non-indexed elements are not-encodable
  -- (with the possible exception of 'n')
  local maxIndex = 0
  for k,v in pairs(t) do
    if (type(k)=='number' and math.floor(k)==k and 1<=k) then	-- k,v is an indexed pair
      if (not isEncodable(v)) then return false end	-- All array elements must be encodable
      maxIndex = math.max(maxIndex,k)
    else
      if (k=='n') then
        if v ~= table.getn(t) then return false end  -- False if n does not hold the number of elements
      else -- Else of (k=='n')
        if isEncodable(v) then return false end
      end  -- End of (k~='n')
    end -- End of k,v not an indexed pair
  end  -- End of loop across all pairs
  return false, maxIndex
end

--- Determines whether the given Lua object / table / variable can be JSON encoded. The only
-- types that are JSON encodable are: string, boolean, number, nil, table and json.null.
-- In this implementation, all other types are ignored.
-- @param o The object to examine.
-- @return boolean True if the object should be JSON encoded, false if it should be ignored.
function isEncodable(o)
  local t = CoreClass.type_name(o)
  return (t=='string' or t=='boolean' or t=='number' or t=='nil' or t=='table' or t=='Vector3' or t=='Rotation' or t=='Color' or t=='callback') or (t=='function' and o==null)
end

-- keep "named" byte values at hands
local c_esc,
    c_e,
    c_l,
    c_r,
    c_u,
    c_f,
    c_a,
    c_s,
    c_slash = ("\\elrufas/"):byte(1,9)

-- token tables - tt_doublequote_string = strDoubleQuot, tt_singlequote_string = strSingleQuot
local
    tt_object_key,
    tt_object_colon,
    tt_object_value,
    tt_doublequote_string,
    tt_singlequote_string,
    tt_array_value,
    tt_array_seperator,
    tt_numeric,
    tt_boolean,
    tt_null,
    tt_comment_start,
    tt_comment_middle,
    tt_ignore --< tt_ignore is special - marked tokens will be tt_ignored
        = {},{},{},{},{},{},{},{},{},{},{},{},{}

-- strings to be used in certain token tables
local strchars = "" -- all valid string characters (all except newlines)
local allchars = "" -- all characters that are valid in comments
--local escapechar = {}
for i=0,0xff do
    local c = string.char(i)
    if c~="\n" and c~="\r" then strchars = strchars .. c end
    allchars = allchars .. c
    --escapechar[i] = "\\" .. string.char(i)
end

--[[
charstounescape = "\"\'\\bfnrt/";
unescapechars = "\"'\\\b\f\n\r\t\/";
for i=1,#charstounescape do
    escapechar[ charstounescape:byte(i) ] = unescapechars:sub(i,i)
end
]]--

-- obj key reader, expects the end of the object or a quoted string as key
init_token_table (tt_object_key) "object (' or \" or } or , expected)"
    :link(tt_singlequote_string) :to "'"
    :link(tt_doublequote_string) :to '"'
    :link(true)                  :to "}"
    :link(tt_object_key)         :to ","
    :link(tt_comment_start)      :to "/"
    :link(tt_ignore)             :to " \t\r\n"


-- after the key, a colon is expected (or comment)
init_token_table (tt_object_colon) "object (: expected)"
    :link(tt_object_value)       :to ":"
    :link(tt_comment_start)      :to "/"
    :link(tt_ignore)             :to" \t\r\n"

-- as values, anything is possible, numbers, arrays, objects, boolean, null, strings
init_token_table (tt_object_value) "object ({ or [ or ' or \" or number or boolean or null expected)"
    :link(tt_object_key)         :to "{"
    :link(tt_array_seperator)    :to "["
    :link(tt_singlequote_string) :to "'"
    :link(tt_doublequote_string) :to '"'
    :link(tt_numeric)            :to "0123456789.-"
    :link(tt_boolean)            :to "tf"
    :link(tt_null)               :to "n"
    :link(tt_comment_start)      :to "/"
    :link(tt_ignore)             :to " \t\r\n"

-- token tables for reading strings
init_token_table (tt_doublequote_string) "double quoted string"
    :link(tt_ignore)             :to (strchars)
    :link(c_esc)                 :to "\\"
    :link(true)                  :to '"'

init_token_table (tt_singlequote_string) "single quoted string"
    :link(tt_ignore)             :to (strchars)
    :link(c_esc)                 :to "\\"
    :link(true)                  :to "'"

-- array reader that expects termination of the array or a comma that indicates the next value
init_token_table (tt_array_value) "array (, or ] expected)"
    :link(tt_array_seperator)    :to ","
    :link(true)                  :to "]"
    :link(tt_comment_start)      :to "/"
    :link(tt_ignore)             :to " \t\r\n"

-- a value, pretty similar to tt_object_value
init_token_table (tt_array_seperator) "array ({ or [ or ' or \" or number or boolean or null expected)"
    :link(tt_object_key)         :to "{"
    :link(tt_array_seperator)    :to "["
    :link(tt_singlequote_string) :to "'"
    :link(tt_doublequote_string) :to '"'
    :link(tt_comment_start)      :to "/"
    :link(tt_numeric)            :to "0123456789.-"
    :link(tt_boolean)            :to "tf"
    :link(tt_null)               :to "n"
    :link(tt_ignore)             :to " \t\r\n"

-- valid number tokens
init_token_table (tt_numeric) "number"
    :link(tt_ignore)             :to "0123456789.-Ee"

-- once a comment has been started with /, a * is expected
init_token_table (tt_comment_start) "comment start (* expected)"
    :link(tt_comment_middle)     :to "*"

-- now everything is allowed, watch out for * though. The next char is then checked manually
init_token_table (tt_comment_middle) "comment end"
    :link(tt_ignore)             :to (allchars)
    :link(true)                  :to "*"

function json.custom_decode (js_string)
    local pos = 1 -- position in the string

    -- read the next byte value
    local function next_byte () pos = pos + 1 return js_string:byte(pos-1) end

    -- in case of error, report the location using line numbers
    local function location ()
        local n = ("\n"):byte()
        local line,lpos = 1,0
        for i=1,pos do
            if js_string:byte(i) == n then
                line,lpos = line + 1,1
            else
                lpos = lpos + 1
            end
        end
        return "Line "..line.." character "..lpos
    end

    -- debug func
    --local function status (str)
    --	print(str.." ("..s:sub(math.max(1,p-10),p+10)..")")
    --end

    -- read the next token, according to the passed token table
    local function next_token (tok)
        while pos <= #js_string do
            local b = js_string:byte(pos)
            local t = tok[b]
            if not t then
                error("Unexpected character at "..location()..": "..
                    string.char(b).." ("..b..") when reading "..tok.name.."\nContext: \n"..
                    js_string:sub(math.max(1,pos-30),pos+30).."\n"..(" "):rep(pos+math.min(-1,30-pos)).."^")
            end
            pos = pos + 1
            if t~=tt_ignore then return t end
        end
        error("unexpected termination of JSON while looking for "..tok.name)
    end

    -- read a string, double and single quoted ones
    local function read_string (tok)
        local start = pos
        --local returnString = {}
        repeat
            local t = next_token(tok)
            if t == c_esc then
                --table.insert(returnString, js_string:sub(start, pos-2))
                --table.insert(returnString, escapechar[ js_string:byte(pos) ])
                pos = pos + 1
                --start = pos
            end -- jump over escaped chars, no matter what
        until t == true
        return (loadstring("return " .. js_string:sub(start-1, pos-1) ) ())

        -- We consider the situation where no escaped chars were encountered separately,
        -- and use the fastest possible return in this case.

        --if 0 == #returnString then
        --	return js_string:sub(start,pos-2)
        --else
        --	table.insert(returnString, js_string:sub(start,pos-2))
        --	return table.concat(returnString,"");
        --end
        --return js_string:sub(start,pos-2)
    end

    local function read_num ()
        local start = pos
        while pos <= #js_string do
            local b = js_string:byte(pos)
            if not tt_numeric[b] then break end
            pos = pos + 1
        end
        return tonumber(js_string:sub(start-1,pos-1))
    end

    -- read_bool and read_null are both making an assumption that I have not tested:
    -- I would expect that the string extraction is more expensive than actually
    -- making manual comparision of the byte values
    local function read_bool ()
        pos = pos + 3
        local a,b,c,d = js_string:byte(pos-3,pos)
        if a == c_r and b == c_u and c == c_e then return true end
        pos = pos + 1
        if a ~= c_a or b ~= c_l or c ~= c_s or d ~= c_e then
            error("Invalid boolean: "..js_string:sub(math.max(1,pos-5),pos+5))
        end
        return false
    end

    -- same as read_bool: only last
    local function read_null ()
        pos = pos + 3
        local u,l1,l2 = js_string:byte(pos-3,pos-1)
        if u == c_u and l1 == c_l and l2 == c_l then return nil end
        error("Invalid value (expected null):"..js_string:sub(pos-4,pos-1)..
            " ("..js_string:byte(pos-1).."="..js_string:sub(pos-1,pos-1).." / "..c_l..")")
    end

    local read_object_value,read_object_key,read_array,read_value,read_comment

    -- read a value depending on what token was returned, might require info what was used (in case of comments)
    function read_value (t,fromt)
        if t == tt_object_key         then return read_object_key({}) end
        if t == tt_array_seperator    then return read_array({}) end
        if t == tt_singlequote_string or
           t == tt_doublequote_string then return read_string(t) end
        if t == tt_numeric            then return read_num() end
        if t == tt_boolean            then return read_bool() end
        if t == tt_null               then return read_null() end
        if t == tt_comment_start      then return read_value(read_comment(fromt)) end
        error("unexpected termination - "..js_string:sub(math.max(1,pos-10),pos+10))
    end

    -- read comments until something noncomment like surfaces, using the token reader which was
    -- used when stumbling over this comment
    function read_comment (fromt)
        while true do
            next_token(tt_comment_start)
            while true do
                local t = next_token(tt_comment_middle)
                if next_byte() == c_slash then
                    local t = next_token(fromt)
                    if t~= tt_comment_start then return t end
                    break
                end
            end
        end
    end

    -- read arrays, empty array expected as o arg
    function read_array (o,i)
        --if not i then status "arr open" end
        i = i or 1
        -- loop until ...
        while true do
            o[i] = read_value(next_token(tt_array_seperator),tt_array_seperator)
            local t = next_token(tt_array_value)
            if t == tt_comment_start then
                t = read_comment(tt_array_value)
            end
            if t == true then  -- ... we found a terminator token
                --status "arr close"
                return o
            end
            i = i + 1
        end
    end

    -- object value reading
    function read_object_value (o)
        local t = next_token(tt_object_value)
        return read_value(t,tt_object_value)
    end

    -- object key reading, might also terminate the object
    function read_object_key (o)
        while true do
            local t = next_token(tt_object_key)
            if t == tt_comment_start then
                t = read_comment(tt_object_key)
            end
            if t == true then return o end
            if t == tt_object_key then return read_object_key(o) end
            local k = read_string(t)

            if next_token(tt_object_colon) == tt_comment_start then
                t = read_comment(tt_object_colon)
            end

            local v = read_object_value(o)
            if CoreClass.type_name(v) == "string" then
                v = BeardLib.Utils:normalize_string_value(v)
            end

            if tonumber(k) ~= nil then
                k = tonumber(k)
            end

            o[k] = v
        end
    end

    -- now let's read data from our string and pretend it's an object value
    local r = read_object_value()
    if pos<=#js_string then
        -- not sure about what to do with dangling characters
        --error("Dangling characters in JSON code ("..location()..")")
    end

    return r
end
