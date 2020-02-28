require "curses"
require 'csv'
require_relative '../station'
include(Curses)

@stations = CSV.parse(File.read('./data/stations.csv')).drop(1).sort.map { |s| Station.new(s.first, s.last.to_i) }

init_screen
noecho
curs_set(0)

@win1 = Window.new(15, 50, 0, 0)
@win1.box('|', '-')

def run
  draw_menu_window(@win1, nil)
  menu(@win1)
end

def draw_menu_window(window, selection_index = nil)
  @stations.each.with_index do |s, i|
    window.setpos(i + 1, 1) # set position to current station
    window.attrset(i == selection_index ? A_STANDOUT : A_NORMAL) # highlight if it matches selection index
    window.addstr(s.name) # write the name of the station
  end
end

def menu(window)
  position = -1
  while (ch = window.getch)
    case ch
    when 'w'
      # draw_info(second_window, 'move up')
      position -= 1
    when 's'
      # draw_info(second_window, 'move down')
      position += 1
    when 'x'
      exit
    end
    position = @stations.length - 1 if position < 0
    position = 0 if position >= @stations.length
    draw_menu_window(window, position)
  end
end

run
