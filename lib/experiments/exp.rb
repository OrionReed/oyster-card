require 'curses'
require_relative 'clui'
include(Curses)

class Exp
  SPEED = 0.01
  HEIGHT = 26
  WIDTH = 100
  CHAR = 'x'
  # REVERSE_AT_COLLISION = proc { |_pos, next_move| :reverse if next_move.strip.empty? }
  ANIMATE_LINE = { move: :left, update: :now, wait: SPEED }

  def initialize
    @ui = CLUI.new(WIDTH, HEIGHT)
    @ui.char_sequence(CHAR, ANIMATE_LINE, WIDTH, HEIGHT)
  end
end

Exp.new
