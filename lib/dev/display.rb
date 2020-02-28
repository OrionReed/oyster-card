module Display
  WIDTH = 60
  HEIGHT = 20
  MAP_SCALE = 10
  WRITING_TIME = 0.01
  TRAVEL_TIME = 0.2
  CHAR = '(--)'
  LEFT = :left
  RIGHT = :right
  CENTER = :center
  REDRAW_LINE = :redraw
  MULTILINE = :multi
  Curses.init_screen

  def self.prompt(s, *_format)
    p_left(s)
    gets.chomp
  end

  def self.puts(s)
    p_left(s)
  end

  def self.draw_list(array)
    array.each { |e| draw(e) }
  end

  def self.newline
    print("\n")
  end

  def self.draw(s)
    s.length.times do |n|
      p_left(s[0..n])
      sleep(WRITING_TIME)
    end
    # newline
  end

  def self.animate_train(start_name, end_name, length)
    length.times do |n|
      p_left("[#{start_name}]#{'-' * n}#{CHAR}#{'-' * (length - n - 1)}[#{end_name}]")
      sleep(TRAVEL_TIME)
    end
    newline
  end

  def self.p_left(s)
    print(left_offset + s.ljust(WIDTH))
    print("\r")
  end

  def self.p_right(s)
  end

  def self.p_center(s)
  end

  def self.left_offset
    " " * ((Curses.cols - WIDTH) / 2)
  end

  def self.right_offset
    " " * ((Curses.cols - WIDTH) / 2)
  end
end
