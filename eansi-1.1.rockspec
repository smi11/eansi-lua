package = "eansi"
version = "1.1"
source = {
  url = "https://github.com/smi/",
  dir = "eansi.lua-1.1"
}
description = {
  summary = "Extended ANSI color handling",
  detailed = [[
    Convert strings describing ANSI colors to extended ANSI escape sequences.
    It supports 3,4,8 and 24 bit ANSI escape sequences.
  ]],
  homepage = "https://github.com/smi/",
  license = "MIT <http://opensource.org/licenses/MIT>"
}
dependencies = {
  "lua >= 5.1"
}
build = {
  type = "builtin",
  modules = {
    ["eansi"] = "eansi.lua"
  },
  copy_directories = {}
}
