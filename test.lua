-- luacheck: ignore 213
-- luacheck: ignore 631

local eansi = require "eansi"

print (eansi._VERSION .. " speed test\n")

local function time(name, loops, f)
  collectgarbage()
  local stime = os.clock()
  eansi.cache = false
  for i = 1, loops do f() end
  print(string.format("%s %i        calls in %.3f seconds, %.1f KB RAM",
                      name, loops, os.clock()-stime, collectgarbage"count"))

  collectgarbage()
  stime = os.clock()
  eansi.cache = true
  for i = 1, loops do f() end
  print(string.format("%s %i cached calls in %.3f seconds, %.1f KB RAM",
                      name, loops, os.clock()-stime, collectgarbage"count"))
end

-- specify number of repetitions as argument 1
local loops = tonumber(arg[1]) or 100000
eansi.enable = true

time("toansi 1 token   ", loops, function() eansi.toansi("bright yellow") end)
time("toansi 5 tokens  ", loops, function() eansi.toansi("italic bold off underline off #7788AA on grey10") end)
time("__index 1 token  ", loops, function() eansi.red("Hello world") end)
time("__index 5 tokens ", loops, function() eansi.bold.underline.italic.blue.on_rgb111("Hello world") end)
time("__call 1 token   ", loops, function() eansi ("${red}red green blue") end)
time("__call 5 tokens  ", loops, function() eansi ("${bold red}red ${green}green ${blue on white}blue") end)
time("paint 1 token    ", loops, function() eansi.paint ("${red}red green blue") end)
time("paint 5 tokens   ", loops, function() eansi.paint ("${bold red}red ${green}green ${blue on white}blue") end)
time("rawpaint 1 token ", loops, function() eansi.rawpaint ("${red}red green blue") end)
time("rawpaint 5 tokens", loops, function() eansi.rawpaint ("${bold red}red ${green}green ${blue on white}blue") end)
time("nopaint 1 token  ", loops, function() eansi.nopaint ("${red}red green blue") end)
time("nopaint 5 tokens ", loops, function() eansi.nopaint ("${bold red}red ${green}green ${blue on white}blue") end)
time("palette 1 token  ", loops, function() eansi.palette("mycolor","bright yellow") end)
time("palette 5 tokens ", loops, function() eansi.palette("mycolor","italic bold off underline off #7788AA on grey10") end)
