require "curses"
include(Curses)

def onsig(sig)
  close_screen
  exit(sig)
end

def ranf
  rand(32767).to_f / 32767
end

%w[HUP INT QUIT TERM].each do |i|
  if trap(i, "SIG_IGN") != 0 # 0 for SIG_IGN
    trap(i) { |sig| onsig(sig) }
  end
end

init_screen
nl
noecho
srand

xpos = {}
ypos = {}
r = lines - 4
c = cols - 4
(0..4).each do |i|
  xpos[i] = (c * ranf).to_i + 2
  ypos[i] = (r * ranf).to_i + 2
end

i = 0
while TRUE
  x = (c * ranf).to_i + 2
  y = (r * ranf).to_i + 2

  setpos(y, x); addstr(".")

  setpos(ypos[i], xpos[i]); addstr("o")

  i = i == 0 ? 4 : i - 1
  setpos(ypos[i], xpos[i]); addstr("O")

  i = i == 0 ? 4 : i - 1
  setpos(ypos[i] - 1, xpos[i]); addstr("-")
  setpos(ypos[i],     xpos[i] - 1); addstr("|.|")
  setpos(ypos[i] + 1, xpos[i]); addstr("-")

  i = i == 0 ? 4 : i - 1
  setpos(ypos[i] - 2, xpos[i]); addstr("-")
  setpos(ypos[i] - 1, xpos[i] - 1); addstr("/ \\")
  setpos(ypos[i],     xpos[i] - 2); addstr("| O |")
  setpos(ypos[i] + 1, xpos[i] - 1); addstr("\\ /")
  setpos(ypos[i] + 2, xpos[i]); addstr("-")

  i = i == 0 ? 4 : i - 1
  setpos(ypos[i] - 2, xpos[i]); addstr(" ")
  setpos(ypos[i] - 1, xpos[i] - 1); addstr("   ")
  setpos(ypos[i],     xpos[i] - 2); addstr("     ")
  setpos(ypos[i] + 1, xpos[i] - 1); addstr("   ")
  setpos(ypos[i] + 2, xpos[i]); addstr(" ")

  xpos[i] = x
  ypos[i] = y
  refresh
  sleep(0.1)
end
