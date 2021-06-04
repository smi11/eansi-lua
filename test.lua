local eansi = require "eansi"

print "speed test"

local tests = {
  "black",
  "red",
  "green",
  "yellow",
  "blue on black",
  "magenta on white",
  "cyan on red",
  "white on bright black",
  "bright black on bright cyan",
  "bright red on bright white",
  "bright green on bright yellow",
  "bold black",
  "dim red",
  "underline green",
  "italic yellow",
  "font4 bright blue on black",
  "double underline magenta on white",
  "slowblink cyan on red",
  "italic off white on bright black",
  "dim off bright black on bright cyan",
  "superscript bright red on bright white",
  "subscript off italic bright green on bright yellow",
  "gray1 on #001122",
  "intense rgb123 on rgb321",
  "double underline color6 on color7",
  "intense #101010 on #AABBCC",
  "frame encircle overline frame off encircle off overline off intense #101010 on #AABBCC"
}

local loops = 10000

for k = 1, 5 do

  local stime = os.clock()
  eansi.cache = false

  for i = 1, loops do
    for _, item in ipairs(tests) do
      eansi.toansi(item)
    end
  end

  print(string.format("%i        calls in %.3f seconds, %.1f KB RAM", loops*#tests, os.clock()-stime, collectgarbage"count"))

  local stime = os.clock()
  eansi.cache = true
  
  for i = 1, loops do
    for _, item in ipairs(tests) do
      eansi.toansi(item)
    end
  end

  print(string.format("%i cached calls in %.3f seconds, %.1f KB RAM", loops*#tests, os.clock()-stime, collectgarbage"count"))
end
