--[[

 eansi 1.2 Easy ANSI Color Maker
 no warranty implied; use at your own risk

 Easy, customizable and flexible way to colorize your terminal output. Convert
 strings describing ANSI colors to extended ANSI escape sequences. Support for
 3,4,8 and 24 bit ANSI escape sequences and thus enabling 8, 16, 256 and 16M
 colors, depending on your terminal capabilities.

 Module offers color tags, HTML tags, simple palette handling, caching, etc..

 See https://en.wikipedia.org/wiki/ANSI_escape_code

 author: Milan Slunečko
 url: https://github.com/smi11/eansi-lua

 DEPENDENCY

 Lua 5.1+ or LuaJIT 2.0+

 BASIC USAGE

 local eansi = require "eansi"

 local mycolor = eansi.toansi "bold bright_yellow on_rgb020"
 print(mycolor .. "some text" .. eansi "") -- eansi "" returns ansi reset string

 print(eansi "${bold red}My ${bold_off green}colorful ${italic blue on_grey3}string")
 print(eansi.underline.on_magenta "Another line of colored text")

 See README.md for documentation

 HISTORY

 1.2 < active
      - replaced argument for rawpaint, paint, nopaint and __call method to be ... vararg
      - minor code improvements

 1.1
      - renamed from colors to eansi
      - changed monkey patch for _G.strings so it is now optional
      - added settings for caching, color tags, HTML tags
      - added simple palette
      - added ansi codes for mintty
      - added ansi codes for underline color
      - refactor code
      - added documentation README.md
      - added busted tests
      - changes to demo.lua
      - first public release

 1.0
      - first draft

 LICENSE

 MIT License. See end of file for full text.

--]]
--           settings
-- luacheck: globals enable htmltags cache _colortag _resetcmd _palette
--           methods
-- luacheck: globals toansi rawpaint paint nopaint palette register
-- luacheck: ignore 131

local fmt = string.format
local concat = table.concat
local select = select
local tostring, tonumber = tostring, tonumber
local _G = _G

local M = { _VERSION = "eansi 1.2" }

local defaults = {
  enable = package.config:sub(1,1) == "/",  -- disabled on windows, enabled other OS's
  htmltags = false,
  cache = true,
  _colortag = "$%b{}",
  _resetcmd = "reset font0",
  _palette = {},
}

-- 8/16 basic color set
local sgr = {

  -- basic attributes
  reset = 0, normal = 0,
  bold = 1, intense = 1,            bold_off = 22, intense_off = 22,
  faint = 2, dim = 2,               faint_off = 22, dim_off = 22,
  italic = 3, oblique = 3,          italic_off = 23, oblique_off = 23,
  underline = 4,                    underline_off = 24,
  blink = 5, slowblink = 5,         blink_off = 25, slowblink_off = 25,
  rapidblink = 6,                   rapidblink_off = 25,
  inverse = 7,                      inverse_off = 27,
  conceal = 8, hide = 8,            reveal = 28, hide_off = 28,
  crossout = 9, strikethrough = 9,  crossout_off = 29, strikethrough_off = 29,

  -- fonts
  font0 = 10, primary_font = 10,
  font1 = 11, font2 = 12, font3 = 13, font4 = 14, font5 = 15,
  font6 = 16, font7 = 17, font8 = 18, font9 = 19,
  fraktur = 20, blackletter = 20, fraktur_off = 23, blackletter_off = 23,

  -- additional attributes
  double_underline = 21,    double_underline_off = 24,
  proportional = 26,        proportional_off = 50,

  -- basic foreground colors
  black = 30,
  red = 31,
  green = 32,
  yellow = 33, brown = 33,
  blue = 34,
  magenta = 35,
  cyan = 36,
  white = 37,
  default = 39, -- set foreground color to default

  -- basic background colors
  on_black = 40,
  on_red = 41,
  on_green = 42,
  on_yellow = 43, on_brown = 43,
  on_blue = 44,
  on_magenta = 45,
  on_cyan = 46,
  on_white = 47,
  on_default = 49, -- set background color to default

  -- additional less supported attributes
  frame = 51,       frame_off = 54,
  encircle = 52,    encircle_off = 54,
  overline = 53,    overline_off = 55,
  default_ulcolor = 59, -- set underline color to default

  -- ideogram attributes 60 to 65 are rarely supported and are not defined here

  -- implemented only in mintty
  -- https://github.com/mintty/mintty/wiki/Tips#text-attributes-and-rendering
  shadow = "1:2",               shadow_off = 22,
  solid_underline = "4:1",      solid_underline_off = 24,
  wavy_underline = "4:3",       wavy_underline_off = 24,
  dotted_underline = "4:4",     dotted_underline_off = 24,
  dashed_underline = "4:5",     dashed_underline_off = 24,
  overstrike = "8:7",           overstrike_off = 28,
  superscript = 73, sup = 73,   superscript_off = 75, sup_off = 75,
  subscript = 74, sub = 74,     subscript_off = 75, sub_off = 75,

  -- bright foreground colors
  bright_black = 90,
  bright_red = 91,
  bright_green = 92,
  bright_yellow = 93,
  bright_blue = 94,
  bright_magenta = 95,
  bright_cyan = 96,
  bright_white = 97,

  -- bright background colors
  on_bright_black = 100,
  on_bright_red = 101,
  on_bright_green = 102,
  on_bright_yellow = 103,
  on_bright_blue = 104,
  on_bright_magenta = 105,
  on_bright_cyan = 106,
  on_bright_white = 107,

  -- internal use - prevent prefixes and suffixes as palette entries
  on = false, bright = false, off = false
}

-- add to sgr 256-color extended color set 38;5;n and 48;5;n (semicolon)
-- add to sgr underline color 58:5:n (colon)
do
  local c

  -- color0 - color15, ulcolor0 - ulcolor15
  for i = 0,255 do
    sgr[   "color"..i] = fmt("38;5;%d",i)
    sgr["on_color"..i] = fmt("48;5;%d",i)
    sgr[ "ulcolor"..i] = fmt("58:5:%d",i)
  end

  -- rgb000-rgb555, color16-color231, ulrgb000-ulrgb555, ulcolor16-ulcolor231
  for r = 0,5 do
    for g = 0,5 do
      for b = 0,5 do
        c = 16 + r*36+ g*6 + b
        sgr[   "rgb"..r..g..b] = fmt("38;5;%d",c)
        sgr["on_rgb"..r..g..b] = fmt("48;5;%d",c)
        sgr[ "ulrgb"..r..g..b] = fmt("58:5:%d",c)
      end
    end
  end

  -- grey0-grey23, color232-color255, ulgrey0-ulgrey23, ulcolor232-ulcolor255
  for i = 0,23 do
    c = i+232
    sgr[   "grey"..i] = fmt("38;5;%d",c)
    sgr["on_grey"..i] = fmt("48;5;%d",c)
    sgr[ "ulgrey"..i] = fmt("58:5:%d",c)
--[[                                        uncomment to add US spelling
    sgr[   "gray"..i] = fmt("38;5;%d",c)
    sgr["on_gray"..i] = fmt("48;5;%d",c)
    sgr[ "ulgray"..i] = fmt("58:5:%d",c)
--]]
  end
end

-- bold, italic, underline, superscript and subscript only
local html = {
  ["b"] = "\27[1m", ["strong"] = "\27[1m", ["/b"] = "\27[22m", ["/strong"] = "\27[22m",
  ["i"] = "\27[3m", ["em"] = "\27[3m",     ["/i"] = "\27[23m", ["/em"] = "\27[23m",
  ["u"] = "\27[4m",                        ["/u"] = "\27[24m",
  ["sup"] = "\27[73m",                     ["/sup"] = "\27[75m",
  ["sub"] = "\27[74m",                     ["/sub"] = "\27[75m",
}

-- caching buffer for toansi()
local toansimemo = setmetatable({}, {__mode = "v"})

-- isolate environment - globals accessible through _G only
if _VERSION < "Lua 5.2" then
  setfenv(1, M)
else
  _ENV = M
end

-- main "work horse" of the module
function toansi(color)
  if not enable then return "" end

  color = tostring(color or "")

  if cache and toansimemo[color] then
    return toansimemo[color].value
  end

  -- replace whitespace with underscore for prefixes "bright", "on" and suffix "off"
  local s = color:gsub("%f[%w]bright%s+","bright_")
                 :gsub("%f[%w]on%s+","on_")
                 :gsub("%s+off%f[%W]","_off")
  local buffer = {}

  for word in s:gmatch("[%S]+") do

    if sgr[word] then
      buffer[#buffer+1] = sgr[word]

    elseif _palette[word] then
      buffer[#buffer+1] = _palette[word] ~= "" and _palette[word] or nil

    elseif word:find("^#%x%x%x%x%x%x$") then
      local r,g,b = word:match("^#(%x%x)(%x%x)(%x%x)")
      buffer[#buffer+1] = fmt("38;2;%d;%d;%d",tonumber(r,16),tonumber(g,16),tonumber(b,16))

    elseif word:find("^on_#%x%x%x%x%x%x$") then
      local r,g,b = word:match("^on_#(%x%x)(%x%x)(%x%x)")
      buffer[#buffer+1] = fmt("48;2;%d;%d;%d",tonumber(r,16),tonumber(g,16),tonumber(b,16))

    elseif word:find("^=[%d:;]+$") then
      buffer[#buffer+1] = word:match("^=([%d:;]+)$")

    else
      _G.error("Invalid token '"..word.."' in color '"..s.."'",2)
    end
  end

  local ret = #buffer > 0 and "\27["..concat(buffer,";").."m" or ""

  if cache then toansimemo[color] = {value = ret} end -- we need object for weak table

  return ret
end

-- convert color tags and html tags in str to ansi escapes
function rawpaint(str, ...)
  str = select("#", ...) == 0 and tostring(str) or concat({str, ...})
  str = str:gsub(_colortag, function(s) return toansi(s:sub(3,-2)) end)
  return htmltags
    and (str:gsub("%b<>", function(s)
                            return not enable and html[s:sub(2,-2)] and ""
                                    or html[s:sub(2,-2)] or s
                          end))
    or   str
end

-- add leading and trailing ansi reset to rawpaint(str)
function paint(...)
  local str = rawpaint(...)
  local reset = toansi(_resetcmd)
  return str == "" and reset or reset .. str .. reset
end

-- remove color tags, html tags and ansi escapes from str
function nopaint(str,...)
  str = select("#", ...) == 0 and tostring(str) or concat({str, ...})
  str = str:gsub(_colortag, ""):gsub("\27%[[%d:;]*m", "")
  return htmltags
    and (str:gsub("%b<>", function(s) return html[s:sub(2,-2)] and "" or s end))
     or  str
end

-- set or remove palette entry
function palette(name, color)
  _G.assert(_G.type(name) == "string" and #name > 0,
            "Name for palette entry must be non-empty string.")
  _G.assert(_G.rawget(M,name) == nil and sgr[name] == nil,
            "Name '"..name.."' for palette entry is already taken.")
  _G.assert(name:find "%s" == nil,
            "Name for palette entry must not have any whitespace.")
  -- invalidate cache for all palette entries containing name
  for ce in _G.pairs(toansimemo) do
    if ce:find(name) then
      toansimemo[ce] = nil
    end
  end
  if not color then
    _palette[name] = nil
  else
    local save = enable; enable = true
    _palette[name] = toansi(color):match("\27%[([%d:;]*)m") or ""
    enable = save
  end
end

-- monkey patch string or some other library
function register(env)
  env = env or _G.string
  _G.assert(_G.type(env)=="table", "Parameter must be a table of existing library or nil")
  env.toansi = toansi
  env.paint = paint
  env.rawpaint = rawpaint
  env.nopaint = nopaint
end

-- make __call call paint()
-- make __index restore defaults & chain color out of subkeys
return _G.setmetatable(M, { __call = function (_, ...) return paint(...) end,
                            __index = function (t, key)
                              -- restore defaults if needed
                              local v = defaults[key]
                              if v ~= nil then
                                if key == "_palette" then v = {} end
                                t[key] = v
                                return v
                              end
                              -- or else check for chain of color keys
                              local mt = {
                                __call = function(_, ...)
                                  local str = concat({...})
                                  return str ~= ""
                                     and paint(toansi(key), str)
                                      or toansi(_resetcmd)
                                end}
                              mt.__index = function(_, subkey)
                                key = key.." "..subkey -- build chain of keys
                                return _G.setmetatable({}, mt)
                              end
                              return _G.setmetatable({}, mt)
                            end})

--[[

MIT License
Copyright (c) 2020 Milan Slunečko

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Except as contained in this notice, the name(s) of the above copyright holders
shall not be used in advertising or otherwise to promote the sale, use or other
dealings in this Software without prior written authorization.

--]]
