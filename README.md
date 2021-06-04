# `eansi.lua`

[![License](https://img.shields.io/:license-mit-blue.svg)](https://mit-license.org)

Convert strings describing ANSI colors to extended ANSI escape sequences.
It supports 3,4,8 and 24 bit ANSI escape sequences and thus enabling 8, 16, 256
and 16M colors, depending on your terminal capabilities.

Color tags, html tags for bold, italic and underline, simple palette handling,
optional caching, saving states, etc.. Highly customizable.

See: <https://en.wikipedia.org/wiki/ANSI_escape_code>

## Installation

### Using LuaRocks

Installing `eansi.lua` using [LuaRocks](https://www.luarocks.org/):

`$ luarocks install eansi`

### Without LuaRocks

Download `eansi.lua` file and put it into the directory for Lua libraries or
your working directory.

## Usage

```
local eansi = require "eansi"

-- settings
eansi.enable = true   -- colors enabled (default false on windows, true on any other os)
eansi.errors = true   -- raise error on invalid color (default true)
eansi.cache = false   -- use caching (defult false)
eansi.tag = "$%b{}"   -- regex for color tags

-- basic methods
eansi.toansi(string)     -- converts string describing colors to ANSI escape sequence
                         -- if eansi.cache is true this function is memoized
eansi.paint(string)      -- convers string with color tags to ANSI escaped string
                         -- also appends ANSI reset sequence before and after string
eansi.rawpaint(string)   -- same as paint but doesn't append ANSI reset sequence
eansi.nopaint(string)    -- returns string stripped of all color tags and ANSI escapes

-- 
eansi.register(table)    -- put eansi methods toansi, paint, rawpaint and nopaint to table
                         -- monkeypatch eansi to your library
eansi.remove(table)      -- remove eansi methods from table

```

## Tests

Clone repository and run `> lua tests.lua`.

## Contributions

If you come across a bug and you'd like to patch it, please fork the repository,
commit your patch, and request a pull.

## Changelog

### 1.1

- refaktor kode, added comments
- first public release

## License

The code is released under the MIT terms. Feel free to use it in both open and
closed software as you please.

MIT License
Copyright (c) 2020-2021 Milan Slunečko

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
