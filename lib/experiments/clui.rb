require 'curses'
class CLUI
  attr_accessor :prim, :seco

  def initialize(x = nil, y = nil)
    @sequence_step = 0
    @x_dir = 0
    @y_dir = 0
    @x_pos = 0
    @y_pos = 0
    init_screen
    curs_set(0)
    noecho
    x = cols if x.nil?
    y = lines if y.nil?
    starty = y.nil? ? 0 : (lines - y) / 2
    startx = x.nil? ? 0 : (cols - x) / 2
    @prim = Window.new(y, x, starty, startx)
  end

  def char_sequence(char, rules, start_x, start_y)
    @prim.setpos(start_y, start_x)
    @prim.addstr("Y: #{@prim.cury}, X: #{@prim.curx}  ")
    @prim.addstr("Start Y: #{start_y}, Start X: #{start_x}")
    @prim.refresh
    sleep(3)
    @prim.addstr("    Y: #{@prim.cury}, X: #{@prim.curx}  ")
    @prim.addstr("Start Y: #{start_y}, Start X: #{start_x}")
    @prim.refresh
    sleep(3)
    loop.with_index do |_, _i|
      rule_move(rules[:move]) unless rules[:move].nil?
      rule_update(rules[:update]) unless rules[:update].nil?
      rule_wait(rules[:wait]) unless rules[:wait].nil?
      do_step(char)
    end
  end

  def do_step(char)
    @prim.addch(char)
    # rule_move(:left)
  end

  def rule_move(val)
    case val
    when :right then
      @x_dir = 1
      @y_dir = 0
    when :left then
      @x_dir = -1
      @y_dir = 0
    when :up then
      @x_dir = 0
      @y_dir = -1
    when :down then
      @x_dir = 0
      @y_dir = 1
    end
    @prim.setpos(@prim.cury + @y_dir, @prim.curx + @x_dir)
  end

  def rule_wait(val)
    sleep(val)
  end

  def rule_update(_val)
    @prim.refresh
  end
end
