--[[

 eansi 1.1 Easy ANSI Color Maker
 no warranty implied; use at your own risk

 Convert strings describing ANSI colors to extended ANSI escape sequences.
 It supports 3,4,8 and 24 bit ANSI escape sequences and thus enabling 8, 16, 256
 and 16M colors, depending on your terminal capabilities.

 See https://en.wikipedia.org/wiki/ANSI_escape_code

 Color tags, html tags, simple palette handling, optional caching, etc..

 author: Milan Slunečko
 url: (maybe github)

 DEPENDENCY

 Lua 5.1+ or LuaJIT 2.0+

 BASIC USAGE

 local eansi = require "eansi"

 local mycolor = eansi.toansi "bold yellow on rgb020"
 io.write(mycolor,"some text",eansi "") -- eansi "" returns ansi reset string

 io.write(eansi "${bold red}My ${bold off green}colorful ${italic blue on gray3}string ")
 io.write(eansi.underline.on_magenta "magenta background and underlined","\n")
 io.write(eansi.red.on_grey5 "easy html tags for <b>bold</b> <i>italic</i> and <u>underline</u>","\n")

 See README.md for documentation

 HISTORY

 1.1 < active
      - renamed from colors to eansi
      - changed monkey patch for _G.strings so it is now optional
      - added settings for caching, color tags, html tags
      - added simple palette
      - refaktor kode
      - first public release

 1.0
      - first basic version


 LICENSE

 MIT Licence. See end of file for full text.

--]]
--           settings
-- luacheck: globals enable html cache errors tag resetcmd __palette
--           methods
-- luacheck: globals toansi rawpaint paint nopaint palette register
-- luacheck: ignore 131

-- %f[%S]'..Word..'%f[%s]

local fmt = string.format
local concat = table.concat
local tostring, tonumber = tostring, tonumber
local _G = _G

local M = { _VERSION = "eansi 1.1" }

local defaults = {
	enable = package.config:sub(1,1) == "/",  -- disabled on windows
	html = true,
	errors = true,
	cache = false,
	tag = "$%b{}",
	resetcmd = "reset font0",
	__palette = {},
}

-- 8/16 basic color set, \27[ {sgr} m
local sgr = {

	-- basic attributes
	reset = 0,     normal = 0,
	bold = 1,      intense = 1,   strong = 1,
	faint = 2,     dark = 2,      dim = 2,
	italic = 3,    oblique = 3,
	underline = 4,
	blink = 5,     slowblink = 5,
	rapidblink = 6,
	inverse = 7,
	conceal = 8,    hide = 8,
	crossout = 9,   strikeout = 9,   strikethrough = 9,

	-- fonts
	font0 = 10,    primary_font = 10,
	font1 = 11,
	font2 = 12,
	font3 = 13,
	font4 = 14,
	font5 = 15,
	font6 = 16,
	font7 = 17,
	font8 = 18,
	font9 = 19,
	fraktur = 20,  blackletter = 20,

	-- additional attributes
	double_underline = 21,
	bold_off = 22,     intense_off = 22, strong_off = 22, dim_off = 22, dark_off = 22, faint_off = 22,
	italic_off = 23,   oblique_off = 23, fraktur_off = 23, blackletter_off = 23,
	underline_off = 24,
	blink_off = 25,
	proportional = 26,
	inverse_off = 27,
	reveal = 28,         conceal_off = 28,    hide_off = 28,
	crossout_off = 29,   strikeout_off = 29,  strikethrough_off = 29,

	-- basic foreground colors
	black = 30,
	red = 31,
	green = 32,
	yellow = 33,
	blue = 34,
	magenta = 35,
	cyan = 36,
	white = 37,
	default = 39, -- set foreground color to default

	-- basic background colors
	on_black = 40,
	on_red = 41,
	on_green = 42,
	on_yellow = 43,
	on_blue = 44,
	on_magenta = 45,
	on_cyan = 46,
	on_white = 47,
	on_default = 49, -- set background color to default

	-- additional less supported attributes
	proportional_off = 50,
	frame = 51,
	encircle = 52,
	overline = 53,
	frame_off = 54,    encircle_off = 54,
	overline_off = 55,

	-- implemented only in mintty
	superscript = 73, 		sup = 73,
	subscript = 74, 			sub = 74,
	superscript_off = 75, subscript_off = 75, sup_off = 75, sub_off = 75,

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

	-- internal use - prevent prefixes and sufixes as palette entries

	on = false, bright = false, off = false, double = false, primary = false,
}

-- add to sgr 256-color extended color set 38;5;n and 48;5;n

-- color0-color255
for i = 0,255 do
	sgr[   "color"..i] = fmt("38;5;%d",i)
	sgr["on_color"..i] = fmt("48;5;%d",i)
end

-- gray0-gray23, grey0-grey23
for i = 0,23 do
	sgr[   "gray"..i] = fmt("38;5;%d",i+232)
	sgr[   "grey"..i] = fmt("38;5;%d",i+232)
	sgr["on_gray"..i] = fmt("48;5;%d",i+232)
	sgr["on_grey"..i] = fmt("48;5;%d",i+232)
end

-- rgb000-rgb555
for r = 0,5 do
	for g = 0,5 do
		for b = 0,5 do
			sgr[   "rgb"..r..g..b] = fmt("38;5;%d",16 + r*36+ g*6 + b)
			sgr["on_rgb"..r..g..b] = fmt("48;5;%d",16 + r*36+ g*6 + b)
		end
	end
end

-- bold, italic, underline, superscript and subscript only
local htmltags = {
	["b"] = "\27[1m",     ["strong"] = "\27[1m",
	["i"] = "\27[3m",     ["em"] = "\27[3m",
	["u"] = "\27[4m",
	["sup"] = "\27[73m",
	["sub"] = "\27[74m",
	["/b"] = "\27[22m",   ["/strong"] = "\27[22m",
	["/i"] = "\27[23m",   ["/em"] = "\27[23m",
	["/u"] = "\27[24m",
	["/sup"] = "\27[75m",
	["/sub"] = "\27[75m",
}

-- create buffer for caching toansi()
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

	color = tostring(color or "") -- color names are case sensitive - use lowercase only

	if cache and toansimemo[color] then
		return toansimemo[color].value
	end

	-- combine multi-word tags by replacing whitespace with underscore
	local s = color:gsub("bright%s+","bright_")
								 :gsub("on%s+","on_")
								 :gsub("%s+off","_off")
								 :gsub("primary%s+font","primary_font")
								 :gsub("double%s+underline","double_underline")
	local buffer = {}

	for word in s:gmatch("[%w#_]+") do

		if sgr[word] then
			buffer[#buffer+1] = sgr[word]

		elseif __palette[word] then
			buffer[#buffer+1] = __palette[word]

		elseif word:find("^#%x%x%x%x%x%x$") then
			local r,g,b = word:match("^#(%x%x)(%x%x)(%x%x)")
			buffer[#buffer+1] = fmt("38;2;%d;%d;%d",tonumber(r,16),tonumber(g,16),tonumber(b,16))

		elseif word:find("^on_#%x%x%x%x%x%x$") then
			local r,g,b = word:match("^on_#(%x%x)(%x%x)(%x%x)")
			buffer[#buffer+1] = fmt("48;2;%d;%d;%d",tonumber(r,16),tonumber(g,16),tonumber(b,16))

		else
			if errors then _G.error("Invalid color '"..word.."' in string '"..s.."'",2) end
			return ""
		end
	end

	local ret = #buffer == 0 and "" or "\27["..concat(buffer,";").."m"

	if cache then toansimemo[color] = {value = ret} end -- we need object for weak table

	return ret
end

-- convert color tags and html tags in str to ansi escapes
function rawpaint(str)
	str = tostring(str or ""):gsub(tag, function(s) return toansi(s:sub(3,-2)) end)
	return html and (str:gsub("%b<>", function(s)
																			return not enable and htmltags[s:sub(2,-2)] and ""
																							or htmltags[s:sub(2,-2)] or s
																		end))
							or	 str
end

-- add leading and trailing ansi reset to rawpaint(str)
function paint(str)
	str = rawpaint(str)
	local reset = toansi(resetcmd)
	return str == "" and reset or reset .. str .. reset
end

-- remove color tags, html tags and ansi escapes from str
function nopaint(str)
	str = tostring(str or ""):gsub(tag, ""):gsub("\27%[[%d;]+m", "")
	return html
		and (str:gsub("%b<>", function(s) return htmltags[s:sub(2,-2)] and "" or s end))
		or	 str
end

-- set or remove palette entry
function palette(name, color)
	_G.assert(_G.type(name) == "string", "name for palette entry must be string")
	_G.assert(M[name] == nil, "Name '"..name.."' should not be eansi method or setting")
	_G.assert(sgr[name] == nil, "Name '"..name.."' should not be ANSI color or attribute or prefix")
	_G.assert(name:find "%s" == nil, "name for palette entry must not have any whitespace")
	if not color then
		__palette[name] = nil  -- when color is nil or false, remove entry from palette
		toansimemo[name] = nil -- also invalidate cache
		return true
	end
	local save = enable; enable = true
	__palette[name] = toansi(color):match("\27%[(.*)m") -- will resolve to nil if invalid color
	enable = save
	if not __palette[name] then
		return false, "Invalid color '"..color.."' for palette entry '"..name.."'"
	end
	return true
end

-- monkey patch string library
function register(env)
	env = env or _G.string
	_G.assert(_G.type(env)=="table", "parameter must be a table of existing library or nil")
	env.toansi = toansi
	env.paint = paint
	env.rawpaint = rawpaint
	env.nopaint = nopaint
end

-- make __call call paint()
-- make __index restore defaults, chain colors out of subkeys
return _G.setmetatable(M, { __call = function (_, s) return paint(s) end,
														__index = function (t, key)
															-- restore defaults if needed
															local v = defaults[key]
															if v ~= nil then
																if key == "__palette" then v = {} end
																t[key] = v
																return v
															end
															-- or else check for chain of color keys
															local mt = {
																__call = function(_, str)
																	str = rawpaint(str)
																	local reset = toansi(resetcmd)
																	return str == "" and reset
																										or reset.. toansi(key)..str..reset
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
