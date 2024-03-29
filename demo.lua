--[[

to force colors from command line:

$ lua demo.lua color

to disable colors from command line:

$ lua demo.lua nocolor

--]]

-- luacheck: ignore 213

local eansi = require "eansi"

if arg[1] == "color" then eansi.enable = true end
if arg[1] == "nocolor" then eansi.enable = false end

-- if no argument specified,
-- default for eansi.enable is false on Windows and true for any other OS

-- assign color palette entries
eansi.palette("title","bold bright yellow on grey5")
eansi.palette("comment","dim italic")

------------------
-- Helpers
------------------

-- comment
local function c(msg)
	return eansi.comment ("-- "..msg)  -- assign color from palette
end

-- comment with leading space
local function sc(msg)
	return eansi.comment (" -- "..msg)  -- assign color from palette
end

-- dump one color
local function d(color)
	return eansi[color] (" "..color.." ") .. " "  -- assign color by its name
end

-- dump a list of colors
local function dl(mask,list,width)
	local buf = {}
	mask = mask.."${reset}"
	for _, v in ipairs(list) do
		buf[#buf+1] = string.format(mask, v,v,v)
	end

  -- get actual width without ansi escapes
	local vw = #eansi.nopaint(table.concat(buf," "))
	local aw = 0
	if width then aw = width - vw end

	return eansi (table.concat(buf," ")) .. string.rep(" ",aw)
end

-- shortcut for io.write
local function out(...)
	io.write(...)
end

-- shortcut for io.write with n linefeeds
local function outlf(n,...)
	out(...)
	out(string.rep("\n",n))
end

local basic_colors = {"black","red","green","yellow","blue","magenta","cyan","white"}
local three = {"red","green","blue"}

outlf(2,eansi.title "Basic colors (8-color mode)")

outlf(1,dl("${%s} %s ",basic_colors))
outlf(2,dl("${on %s} %s ",basic_colors), sc"'on_'")

outlf(2,"Usage: ",d"on green",d"white on blue",d"magenta on white")

outlf(2,eansi.title "Extended 'bright' colors (16-color mode)")

outlf(1,dl("${%s} %s ",basic_colors))
outlf(1,dl("${bright %s} %s ",basic_colors), sc"'bright_'")
outlf(1,dl("${on %s} %s ",basic_colors), sc"'on_'")
outlf(2,dl("${on bright %s} %s ",basic_colors), sc"'on_bright_'")

outlf(2,"Usage: ",d"on_bright_magenta",d"bright_yellow",d"bright_red on_bright_white")

outlf(2,eansi.title "Basic SGR Attributes",
				sc"Some attributes may ${underline}not work${underline off} in you terminal")

outlf(2,dl("${%s} %s ",{"bold","faint","italic","underline","blink","rapidblink","inverse","crossout"}))

outlf(2,eansi.title "Additional SGR Attributes",
				sc"Sometimes supported")

outlf(2,dl("${%s} %s ",{"double_underline","frame","encircle","overline","proportional"}))

outlf(2,c"Supported only in mintty")

outlf(1,dl("${%s} %s ",{"shadow","overstrike","superscript","subscript"}))
outlf(2,dl("${%s} %s ",{"solid_underline","wavy_underline","dotted_underline","dashed_underline"}))

outlf(2,c"Underline color")

outlf(1,dl("${underline ulcolor%s} %s ",{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}))
outlf(2,dl("${double_underline ulcolor%s} %s ",{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}))

outlf(2,c"Aliases for SGR Attributes","          ",c"Shades using attributes")

outlf(1,dl("${%s} %s ",{"normal","reset"},38),          dl("${dim %s} %s ",three), " ", c"'dim'")
outlf(1,dl("${%s} %s ",{"font0","primary_font"},38),    dl("${%s} %s ",three))
outlf(1,dl("${%s} %s ",{"bold","intense"},38),          dl("${bright %s} %s ",three), " ", c"'bright_'")
outlf(1,dl("${%s} %s ",{"dim","faint"},38),             dl("${bold %s} %s ",three), " ", c"'bold'")
outlf(1,dl("${%s} %s ",{"italic","oblique"},38),        dl("${bold bright %s} %s ",three), " ", c"'bold bright_'")
outlf(2,dl("${%s} %s ",{"crossout","strikethrough"},38))

outlf(2,c"Turn off attributes using suffix '_off', e.g. 'dim_off'")

outlf(2,"Usage: ",d"underline on_blue", d"italic overline cyan", d"dim crossout yellow")

outlf(2,eansi.title "Fonts",
				sc"You probably need to set them up in your terminal")
outlf(1,dl("${%s} %s ",{"font0","blackletter"}))
outlf(2,dl("${%s} %s ",{"font1","font2","font3","font4","font5","font6","font7","font8","font9"}))

-- monkey patch string library with eansi functions so we can use oop syntax sugar
eansi.register()

outlf(2,eansi.title "Extended colors (256 color mode)")

outlf(2,"color0 .. color15 / on_color0 .. on_color15")

local cnt = function(n,m)
	if n < 3 then return n
	elseif n > m - 1 then return n
	elseif (n < 6) or (n > m - 4) then return "."
	else return ""
	end
end

for i=0,15 do out(string.format("%2s",cnt(i,15)):paint()) end outlf(1)
for i=0,15 do out(string.format("${color%d}██",i):paint()) end
outlf(2)

out(("rgb${red}0${green}0${blue}0${reset} .. rgb${red}5${green}5${blue}5"):paint()," / ")
outlf(2,("on_rgb${red}0${green}0${blue}0${reset} .. on_rgb${red}5${green}5${blue}5"):paint())

out("  ")
for g = 0,5 do
	out(string.format("${green}%d            ",g):paint())
end
out("\n  ")

for g = 0,5 do
	for b = 0,5 do
		out(string.format("${blue}%d ",b):paint())
	end
	out(" ")
end
outlf(1)

for r = 0,5 do
	out(string.format("${red}%d ",r):paint())
	for g = 0,5 do
		for b = 0,5 do
			out(eansi.toansi("rgb"..r..g..b),"██")
		end
		out(eansi " ")
	end
	outlf(1)
end

outlf(1)
outlf(2,"grey0 .. grey23 / on_grey0 .. on_grey23")

for i=0,23 do out(string.format("%2s",cnt(i,23))) end outlf(1)
for i=0,23 do out(string.format("${grey%d}██",i):paint()) end
outlf(1)

outlf(2,"\n",eansi.title "Full 24 bit colors (16M color mode)")

out(("#${red}00${green}00${blue}00${reset} .. #${red}FF${green}FF${blue}FF"):paint()," / ")
outlf(2,("on_#${red}00${green}00${blue}00${reset} .. on_#${red}FF${green}FF${blue}FF"):paint())

outlf(1,"0...",string.rep(" ",55),"...FF")
for i = 0,255,4 do out(string.format("#%.2x0000",i):toansi(),"█") end outlf(1,eansi "")
for i = 0,255,4 do out(string.format("#00%.2x00",i):toansi(),"█") end outlf(1,eansi "")
for i = 0,255,4 do out(string.format("#0000%.2x",i):toansi(),"█") end outlf(2,eansi "")
