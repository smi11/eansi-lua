local eansi = require "eansi"

local test_sgr = {
	"reset",
	"normal",
	"bold",
	"intense",
	"strong",
	"faint",
	"dark",
	"dim",
	"italic",
	"oblique",
	"underline",
	"blink",
	"slowblink",
	"rapidblink",
	"inverse",
	"conceal",
	"strikeout",
	"crossout",
	"font0",
	"primary font",
	"font1",
	"font2",
	"font3",
	"font4",
	"font5",
	"font6",
	"font7",
	"font8",
	"font9",
	"fraktur",
	"blackletter",
	"double underline",
	"bold off",
	"intense off",
	"strong off",
	"dim off",
	"dark off",
	"faint off",
	"italic off",
	"oblique off",
	"fraktur off",
	"blackletter off",
	"underline off",
	"blink off",
	"proportional",
	"inverse off",
	"reveal",
	"conceal off",
	"strikeout off",
	"crossout off",
	"black",
	"red",
	"green",
	"yellow",
	"blue",
	"magenta",
	"cyan",
	"white",
	"default",
	"on black",
	"on red",
	"on green",
	"on yellow",
	"on blue",
	"on magenta",
	"on cyan",
	"on white",
	"on default",
	"proportional off",
	"frame",
	"encircle",
	"overline",
	"frame off",
	"encircle off",
	"overline off",
	"superscript",
	"subscript",
	"superscript off",
	"subscript off",
	"bright black",
	"bright red",
	"bright green",
	"bright yellow",
	"bright blue",
	"bright magenta",
	"bright cyan",
	"bright white",
	"on bright black",
	"on bright red",
	"on bright green",
	"on bright yellow",
	"on bright blue",
	"on bright magenta",
	"on bright cyan",
	"on bright white",
}

describe("options", function()
	it("should be set to defaul values", function()
		eansi.enable = nil
		assert.equal(package.config:sub(1,1) == "/", eansi.enable)
		eansi.html = nil
		assert.equal(true, eansi.html)
		eansi.errors = nil
		assert.equal(true, eansi.errors)
		eansi.cache = nil
		assert.equal(false, eansi.cache)
		eansi.tag = nil
		assert.equal("$%b{}", eansi.tag)
		eansi.resetcmd = nil
		assert.equal("reset font0", eansi.resetcmd)
		eansi.__pallete = nil
		assert.same({}, eansi.__pallete)
	end)
end)

describe("toansi()", function()
	it("should return \"\" when disabled", function()
		eansi.enable = false
		for _, item in ipairs(test_sgr) do
			assert(eansi.toansi(item) == "")
		end
	end)

	it("should return ansi escape sequence", function()
		eansi.enable = true
		for _, item in ipairs(test_sgr) do
			local result = eansi.toansi(item)
			assert(string.find(result, "^\27%[[%d;]-m$") == 1)
		end
	end)

	it("should handle basic ansi escapes", function()
		eansi.enable = true
		assert.equal("", eansi.toansi"")
		assert.equal("\27[0;10m", eansi.toansi"reset font0")
		assert.equal("\27[31m", eansi.toansi"red")
		assert.equal("\27[42m", eansi.toansi"on green")
		assert.equal("\27[1;46m", eansi.toansi"bold on cyan")
		assert.equal("\27[90m", eansi.toansi"bright black")
		assert.equal("\27[107m", eansi.toansi"on bright white")
		assert.equal("\27[1;3;5;14;4;53;91;74;107m", eansi.toansi"intense italic blink font4 underline overline bright red subscript on bright white")
	end)

	it("should allow for extra whitespace", function()
		eansi.enable = true
		assert.equal("", eansi.toansi"")
		assert.equal("\27[0;10m", eansi.toansi"   reset font0")
		assert.equal("\27[31m", eansi.toansi"red   ")
		assert.equal("\27[42m", eansi.toansi"on  \t\n\r  green")
		assert.equal("\27[1;46m", eansi.toansi"\t\t\t bold  \n\r on  \v cyan   ")
		assert.equal("\27[90m", eansi.toansi"bright  \tblack      \t\t          ")
		assert.equal("\27[107m", eansi.toansi"        \n\r       on bright\twhite")
		assert.equal("\27[38;2;17;34;51m", eansi.toansi"        \n\r  #112233   \t")
		assert.equal("\27[48;2;51;34;17m", eansi.toansi"      on   \n\r #332211   \t")
	end)

	it("should handle extended ansi escapes", function()
		eansi.enable = true
		assert.equal("\27[38;5;0m", eansi.toansi"color0")
		assert.equal("\27[38;5;15m", eansi.toansi"color15")
		assert.equal("\27[38;5;255m", eansi.toansi"color255")
		assert.equal("\27[38;5;232m", eansi.toansi"gray0")
		assert.equal("\27[38;5;255m", eansi.toansi"gray23")
		assert.equal("\27[38;5;16m", eansi.toansi"rgb000")
		assert.equal("\27[38;5;231m", eansi.toansi"rgb555")

		assert.equal("\27[48;5;0m", eansi.toansi"on color0" )
		assert.equal("\27[48;5;15m", eansi.toansi"on color15" )
		assert.equal("\27[48;5;255m", eansi.toansi"on color255" )
		assert.equal("\27[48;5;232m", eansi.toansi"on gray0" )
		assert.equal("\27[48;5;255m", eansi.toansi"on gray23" )
		assert.equal("\27[48;5;16m", eansi.toansi"on rgb000" )
		assert.equal("\27[48;5;231m", eansi.toansi"on rgb555" )

		assert.equal("\27[38;2;0;0;0m", eansi.toansi"#000000")
		assert.equal("\27[38;2;255;255;255m", eansi.toansi"#ffffFF")
		assert.equal("\27[48;2;0;0;0m", eansi.toansi"on #000000")
		assert.equal("\27[48;2;255;255;255m", eansi.toansi"on #ffffFF")
	end)

	it("should handle mixed ansi escapes", function()
		eansi.enable = true
		assert.equal("\27[2;33;48;2;1;1;1m", eansi.toansi"dim yellow on #010101")
		assert.equal("\27[21;2;38;5;11;48;5;254m", eansi.toansi"double underline dim color11 on gray22")
	end)

	it("should return \"\" for invalid colors", function()
		eansi.errors = false
		eansi.enable = true
		assert.equal("", eansi.toansi"on rgb666")
		assert.equal("", eansi.toansi"some rubish")
		assert.equal("", eansi.toansi{})
		assert.equal("", eansi.toansi(123))
		assert.equal("", eansi.toansi(false))
	end)

	it("should raise error for invalid colors", function()
		eansi.errors = true
		eansi.enable = true
		assert.has_error(function() eansi.toansi "on rgb777" end, "Invalid color 'on_rgb777' in string 'on_rgb777'")
		assert.has_error(function() eansi.toansi(123) end, "Invalid color '123' in string '123'")
		assert.has_no_error(function() eansi.toansi "black" end)
	end)
end)

-------------------------------------------------------------------------

describe("rawpaint()", function()
	it("should leave string without tags as it is", function()
		eansi.enable = true
		assert.equal("This is string without color tags", eansi.rawpaint "This is string without color tags")
		assert.equal("This is <span>string</span> without color tags", eansi.rawpaint "This is <span>string</span> without color tags")
		assert.equal("", eansi.rawpaint "")
	end)

	it("should remove all tags", function()
		eansi.enable = false
		eansi.html = true
		assert.equal("This is string without color tags", eansi.rawpaint "This is ${red}string ${green}without color tags")
		assert.equal("This is string without <c>color</c> tags", eansi.rawpaint "This is <b>string</b> without <c>color</c> tags")
		assert.equal("bold, italic, underline, <xx>rubish</xx>", eansi.rawpaint "<b>bold</b>, <i>italic</i>, <u>underline</u>, <xx>rubish</xx>")
		assert.equal("bold, italic, underline, <yy>rubish</yy>", eansi.rawpaint "<strong>bold</strong>, <em>italic</em>, <u>underline</u>, <yy>rubish</yy>")
		assert.equal("", eansi.rawpaint "")
	end)

	it("should remove color tags and keep html tags", function()
		eansi.enable = false
		eansi.html = false
		assert.equal("This is string without color tags", eansi.rawpaint "This is ${red}string ${green}without color tags")
		assert.equal("This is <b>string</b> without <c>color</c> tags", eansi.rawpaint "This is <b>string</b> without <c>color</c> tags")
		assert.equal("<b>bold</b>, <i>italic</i>, <u>underline</u>, <xx>rubish</xx>", eansi.rawpaint "<b>bold</b>, <i>italic</i>, <u>underline</u>, <xx>rubish</xx>")
		assert.equal("<strong>bold</strong>, <em>italic</em>, <u>underline</u>, <yy>rubish</yy>", eansi.rawpaint "<strong>bold</strong>, <em>italic</em>, <u>underline</u>, <yy>rubish</yy>")
		assert.equal("", eansi.rawpaint "")
	end)

	it("should replace color tags with ansi escapes", function()
		eansi.enable = true
		assert.equal("\27[31mword \27[32mword", eansi.rawpaint "${red}word ${green}word")
		assert.equal("something \27[1mbold\27[0m is also \27[1mstrong\27[0m", eansi.rawpaint "something ${bold}bold${reset} is also ${strong}strong${reset}")
		assert.equal("no color tags", eansi.rawpaint "no color tags")
		assert.equal("", eansi.rawpaint "")
	end)

	it("should replace all tags with ansi escapes", function()
		eansi.enable = true
		eansi.html = true
		assert.equal("This is \27[1mstring\27[22m without <c>color</c> tags", eansi.rawpaint "This is <b>string</b> without <c>color</c> tags")
		assert.equal("\27[1mbold\27[22m, \27[3mitalic\27[23m, \27[4munderline\27[24m, <xx>rubish</xx>", eansi.rawpaint "<b>bold</b>, <i>italic</i>, <u>underline</u>, <xx>rubish</xx>")
		assert.equal("\27[1mbold\27[22m, \27[3mitalic\27[23m, \27[4munderline\27[24m, <yy>rubish</yy>", eansi.rawpaint "<strong>bold</strong>, <em>italic</em>, <u>underline</u>, <yy>rubish</yy>")
		assert.equal("no html tags", eansi.rawpaint "no html tags")
		assert.equal("", eansi.rawpaint "")
	end)
end)

-------------------------------------------------------------------------

describe("paint()", function()
	it("should replace all tags with ansi escapes and add reset", function()
		eansi.enable = true
		eansi.html = true
		local reset = eansi.toansi(eansi.resetcmd)
		assert.equal(reset.."This is \27[1mstring\27[22m without <c>color</c> tags"..reset, eansi.paint "This is <b>string</b> without <c>color</c> tags")
		assert.equal(reset.."\27[1mbold\27[22m, \27[3mitalic\27[23m, \27[4munderline\27[24m, <xx>rubish</xx>"..reset, eansi.paint "<b>bold</b>, <i>italic</i>, <u>underline</u>, <xx>rubish</xx>")
		assert.equal(reset.."\27[1mbold\27[22m, \27[3mitalic\27[23m, \27[4munderline\27[24m, <yy>rubish</yy>"..reset, eansi.paint "<strong>bold</strong>, <em>italic</em>, <u>underline</u>, <yy>rubish</yy>")
		assert.equal(reset.."no html tags"..reset, eansi.paint "no html tags")
	end)

	it("should add only one reset for empty string", function()
		eansi.enable = true
		assert.equal(eansi.toansi(eansi.resetcmd), eansi.paint "")
	end)
end)

-------------------------------------------------------------------------

describe("nopaint()", function()
	it("should remove only color tags and ansi escapes", function()
		eansi.enable = true
		eansi.html = false
		assert.equal("This is string without color tags", eansi.nopaint "This is ${red}string ${green}without color tags")
		assert.equal("This is <b>string</b> without <c>color</c> tags", eansi.nopaint "This is <b>string</b> without <c>color</c> tags")
		assert.equal("This is string without <b>color</b> tags", eansi.nopaint "\27[1mThis is ${red}string ${green}without <b>color</b> tags\27[0m")
		assert.equal("", eansi.rawpaint "")
		eansi.enable = false
		assert.equal("This is string without color tags", eansi.nopaint "This is ${red}string ${green}without color tags")
		assert.equal("This is <b>string</b> without <c>color</c> tags", eansi.nopaint "This is <b>string</b> without <c>color</c> tags")
		assert.equal("This is string without <b>color</b> tags", eansi.nopaint "\27[1mThis is ${red}string ${green}without <b>color</b> tags\27[0m")
		assert.equal("", eansi.rawpaint "")
	end)

	it("should remove all tags and ansi escapes", function()
		eansi.enable = true
		eansi.html = true
		assert.equal("This is string without color tags", eansi.nopaint "This is ${red}string ${green}without color tags")
		assert.equal("This is string without <c>color</c> tags", eansi.nopaint "This is <b>string</b> without <c>color</c> tags")
		assert.equal("This is string without color tags", eansi.nopaint "\27[1mThis is ${red}string ${green}without <b>color</b> tags\27[0m")
		assert.equal("", eansi.rawpaint "")
		eansi.enable = false
		assert.equal("This is string without color tags", eansi.nopaint "This is ${red}string ${green}without color tags")
		assert.equal("This is string without <c>color</c> tags", eansi.nopaint "This is <b>string</b> without <c>color</c> tags")
		assert.equal("This is string without color tags", eansi.nopaint "\27[1mThis is ${red}string ${green}without <b>color</b> tags\27[0m")
		assert.equal("", eansi.rawpaint "")
	end)

end)

-------------------------------------------------------------------------

describe("__call and __index metamethods", function()
	it("should work as paint()", function()
		eansi.enable = true
		eansi.html = true
		local reset = eansi.toansi(eansi.resetcmd)
		assert.equal(reset.."\27[31mhello"..reset, eansi.red "hello")
		assert.equal(reset.."\27[31mhello \27[34mblue \27[1mworld"..reset, eansi.red "hello ${blue}blue <b>world")
		assert.equal(reset.."\27[31;7mhello \27[34mblue \27[1mworld"..reset, eansi.red.inverse "hello ${blue}blue <b>world")
		eansi.html = false
		assert.equal(reset.."\27[31mhello"..reset, eansi.red "hello")
		assert.equal(reset.."\27[31mhello \27[34mblue <b>world"..reset, eansi.red "hello ${blue}blue <b>world")
		assert.equal(reset.."\27[31;7mhello \27[34mblue <b>world"..reset, eansi.red.inverse "hello ${blue}blue <b>world")
		eansi.enable = false
		eansi.html = true
		assert.equal("hello", eansi.red "hello")
		assert.equal("hello blue world", eansi.red "hello ${blue}blue <b>world")
		assert.equal("hello blue world", eansi.red.inverse "hello ${blue}blue <b>world")
		eansi.html = false
		assert.equal("hello blue <b>world", eansi.red "hello ${blue}blue <b>world")
		assert.equal("hello blue <b>world", eansi.red.inverse "hello ${blue}blue <b>world")
	end)

end)

-------------------------------------------------------------------------

describe("custom tag regex", function()
	it("should work for all functions", function()
		eansi.enable = true
		eansi.tag = "$%b{}"
		local reset = eansi.toansi(eansi.resetcmd)
		assert.equal(reset.."hello \27[1mworld"..reset, eansi "hello ${bold}world")
		assert.equal(reset.."hello \27[1mworld"..reset, eansi.paint "hello ${bold}world")
		assert.equal("hello \27[1mworld", eansi.rawpaint "hello ${bold}world")
		assert.equal("hello world", eansi.nopaint "hello ${bold}world")
		eansi.tag = "$%b()"
		assert.equal(reset.."hello \27[1mworld"..reset, eansi "hello $(bold)world")
		assert.equal(reset.."hello \27[1mworld"..reset, eansi.paint "hello $(bold)world")
		assert.equal("hello \27[1mworld", eansi.rawpaint "hello $(bold)world")
		assert.equal("hello world", eansi.nopaint "hello $(bold)world")
		eansi.tag = "$%b[]"
		assert.equal(reset.."hello \27[1mworld"..reset, eansi "hello $[bold]world")
		assert.equal(reset.."hello \27[1mworld"..reset, eansi.paint "hello $[bold]world")
		assert.equal("hello \27[1mworld", eansi.rawpaint "hello $[bold]world")
		assert.equal("hello world", eansi.nopaint "hello $[bold]world")
		eansi.tag = "%%%b{}" -- % should be escaped with %
		assert.equal(reset.."hello \27[1mworld"..reset, eansi "hello %{bold}world")
		assert.equal(reset.."hello \27[1mworld"..reset, eansi.paint "hello %{bold}world")
		assert.equal("hello \27[1mworld", eansi.rawpaint "hello %{bold}world")
		assert.equal("hello world", eansi.nopaint "hello %{bold}world")
		eansi.tag = ":%b{}"
		assert.equal(reset.."hello \27[1mworld"..reset, eansi "hello :{bold}world")
		assert.equal(reset.."hello \27[1mworld"..reset, eansi.paint "hello :{bold}world")
		assert.equal("hello \27[1mworld", eansi.rawpaint "hello :{bold}world")
		assert.equal("hello world", eansi.nopaint "hello :{bold}world")
		eansi.tag = nil
	end)

end)

-------------------------------------------------------------------------

describe("palette()", function()
	it("should set new palette entries", function()
		eansi.enable = true
		local reset = eansi.toansi(eansi.resetcmd)
		assert.equal(true, eansi.palette("alert", "red on white"))
		assert.equal("31;47", eansi.__palette["alert"])
		assert.equal(reset.."\27[31;47mhello"..reset, eansi.alert "hello")
		assert.equal(reset.."\27[31;47mhello"..reset, eansi "${alert}hello")
		assert.equal(reset.."\27[1;31;47mhello"..reset, eansi "${bold alert}hello")
		assert.equal(reset.."\27[1;31;47mhello"..reset, eansi.bold.alert "hello")
		assert.equal(reset, eansi.alert "")
		eansi.enable = false
		assert.equal("hello", eansi.alert "hello")
	end)

	it("should erase palette entries", function()
		eansi.enable = true
		eansi.errors = true
		assert.equal(true,eansi.palette("alert", nil))
		assert.equal(nil, eansi.__palette["alert"])
		assert.has_error(function() eansi.alert "hello" end, "Invalid color 'alert' in string 'alert'")
	end)

	it("should report error", function()
		eansi.enable = true
		eansi.errors = false
		local stat, err = eansi.palette("test", "some rubish")
		assert.equal(false, stat)
		assert.equal("Invalid color 'some rubish' for palette entry 'test'", err)
		assert.has_error(function() eansi.palette (123, "blue") end, "name for palette entry must be string")
		assert.has_error(function() eansi.palette ("red", "blue") end, "Name 'red' should not be ANSI color or attribute or prefix")
		assert.has_error(function() eansi.palette ("off", "blue") end, "Name 'off' should not be ANSI color or attribute or prefix")
		assert.has_error(function() eansi.palette ("pink elephant", "blue") end, "name for palette entry must not have any whitespace")
	end)
end)

-------------------------------------------------------------------------

describe("register()", function()
	it("should patch _G.string with 4 functions", function()
		eansi.register()
		assert.equal(string.toansi, eansi.toansi)
		assert.equal(string.paint, eansi.paint)
		assert.equal(string.rawpaint, eansi.rawpaint)
		assert.equal(string.nopaint, eansi.nopaint)
	end)
end)

-------------------------------------------------------------------------

