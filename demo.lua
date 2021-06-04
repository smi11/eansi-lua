--[[

to force colors from command line run:

> lua demo.lua color

to disable colors from command line run:

> lua demo.lua nocolor

--]]

local eansi = require "eansi"

if arg[1] == "color" then eansi.enable = true end
if arg[1] == "nocolor" then eansi.enable = false end

-- if no argument specified,
-- default for eansi.enable is false on Windows and true for any other OS

-- assign color palette entries
eansi.palette("title","intense bright yellow")
eansi.palette("comment","dim italic")

------------------
-- Helpers
------------------

-- title
local function t(msg)
	return eansi.title (msg)   -- assign color from palette
                         -- we could also do eansi.intense.bright_yellow (msg)
end

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

-- dump one color with mask
local function dm(mask,color)
	return eansi (string.format(mask, color, color)) .. " " -- use color tags from mask
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

outlf(2, t"Basic colors (8-color mode)")

outlf(1,dl("${%s} %s ",basic_colors))
outlf(2,dl("${on %s} %s ",basic_colors), sc"'on'")

outlf(2,"Usage: ",d"on green",d"white on blue",d"magenta on white")

outlf(2,t"Extended 'bright' colors (16-color mode)")

outlf(1,dl("${%s} %s ",basic_colors))
outlf(1,dl("${bright %s} %s ",basic_colors), sc"'bright'")
outlf(1,dl("${on %s} %s ",basic_colors), sc"'on'")
outlf(2,dl("${on bright %s} %s ",basic_colors), sc"'on bright'")

outlf(2,"Usage: ",d"on bright magenta",d"bright yellow",d"bright red on bright white")

outlf(2,t"SGR Attributes",sc"Some attributes will probably ${underline}not work${underline off}")

outlf(1,dl("${%s} %s ",{"bold","faint","italic","underline","blink","rapidblink","inverse","crossout"}))
outlf(1,dl("${%s} %s ",{"fraktur","double underline","frame","encircle","overline"}))
outlf(1,dl("${%s} %s ",{"conceal","proportional","superscript","subscript"}))
outlf(2,dl("${%s} %s ",{"font0","font1","font2","font3","font4","font5","font6","font7","font8","font9"}))

outlf(2,c"Aliases for SGR Attributes","          ",c"Shades using attributes")

outlf(1,dl("${%s} %s ",{"normal","reset"},38),          dl("${dim %s} %s ",three), " ", c"'dim'")
outlf(1,dl("${%s} %s ",{"font0","primary font"},38),    dl("${%s} %s ",three))
outlf(1,dl("${%s} %s ",{"bold","intense","strong"},38), dl("${bright %s} %s ",three), " ", c"'bright'")
outlf(1,dl("${%s} %s ",{"dim","faint","dark"},38),      dl("${bold %s} %s ",three), " ", c"'bold'")
outlf(1,dl("${%s} %s ",{"italic","oblique"},38),        dl("${bold bright %s} %s ",three), " ", c"'bold bright'")
outlf(2,dl("${%s} %s ",{"crossout","strikeout","strikethrough"},38))

outlf(2,c"Turn off attributes using suffix 'off', e.g. 'dim off'")

outlf(2,"Usage: ",d"underline on blue", d"italic overline cyan", d"dim crossout white")

-- monkey patch string library with eansi functions so we can use oop syntax sugar
eansi.register()

outlf(2,t"Extended colors (256 color mode)")

outlf(2,"color0 .. color15 / on color0 .. on color15")

cnt = function(n,m)
	if n < 3 then return n
	elseif n > m - 1 then return n
	elseif (n < 6) or (n > m - 4) then return "."
	else return ""
	end
end

for i=0,15 do out(string.format("%2s",cnt(i,15)):paint()) end outlf(1)
for i=0,15 do out(string.format("${color%d}██",i):paint()) end
outlf(2)

outlf(2,"gray0 .. gray23 / on gray0 .. on gray23")

for i=0,23 do out(string.format("%2s",cnt(i,23))) end outlf(1)
for i=0,23 do out(string.format("${gray%d}██",i):paint()) end
outlf(2)

out(("rgb${red}0${green}0${blue}0${reset} .. rgb${red}5${green}5${blue}5"):paint()," / ")
outlf(2,("on rgb${red}0${green}0${blue}0${reset} .. on rgb${red}5${green}5${blue}5"):paint())

out("  ")
for g = 0,5 do
	out(string.format("${green}%d             ",g):paint())
end
out("\n  ")

for g = 0,5 do
	for b = 0,5 do
		out(string.format("${blue}%d ",b):paint())
	end
	out("  ")
end
outlf(1)

for r = 0,5 do
	out(string.format("${red}%d ",r):paint())
	for g = 0,5 do
		for b = 0,5 do
			out(eansi.toansi("rgb"..r..g..b),"██")
		end
		out(eansi "  ")
	end
	outlf(1)
end

outlf(2,t"\nFull 24 bit colors (16M color mode)")

out(("#${red}00${green}00${blue}00${reset} .. #${red}FF${green}FF${blue}FF"):paint()," / ")
outlf(2,("on #${red}00${green}00${blue}00${reset} .. on #${red}FF${green}FF${blue}FF"):paint())

outlf(1,"0...",string.rep(" ",55),"...FF")
for i = 0,255,4 do out(string.format("#%.2x0000",i):toansi(),"█") end outlf(1,eansi "")
for i = 0,255,4 do out(string.format("#00%.2x00",i):toansi(),"█") end outlf(1,eansi "")
for i = 0,255,4 do out(string.format("#0000%.2x",i):toansi(),"█") end outlf(2,eansi "")
