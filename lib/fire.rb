require "curses"
include(Curses)

class Fire
  def initialize
    screen  = init_screen
    width   = screen.maxx
    height  = screen.maxy
    size    = width * height
    char    = [" ", ".", ":", "^", "*", "x", "s", "S", "#", "$"]
    b       = []
  end

  curs_set(0)
  curs_set(0)
  start_color
  init_pair(1, 0, 0)
  init_pair(2, 1, 0)
  init_pair(3, 3, 0)
  init_pair(4, 4, 0)
  clear
  (size + width + 1).times do
    b.append(0)
  end

  loop do
    (0..width / 9).each do |_n|
      b[int((random.random * width) + width * (height - 1))] = 65
    end

    range(0..size).each do |i|
      b[i] = (b[i] + b[i + 1] + b[i + width] + b[i + width + 1]) / 4
      color = if b[i] > 15
        4
      elsif b[i] > 9
        3
      elsif b[i] > 4
        2
      else
        1
      end
    end
    if i < size - 1
      screen.addstr(int(i / width),
      i % width,
      char[(b[i] > 9 ? 9 : b[i])],
      curses.color_pair(color) | curses.A_BOLD)
    end
    screen.refresh
    screen.timeout(30)
    if screen.getch != -1 then break end
  end

  curses.endwin
end

Fire.new.run
