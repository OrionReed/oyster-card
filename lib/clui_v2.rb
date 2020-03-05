require 'curses'
include(Curses)
class CLUIV2
  attr_accessor :prim, :seco

  def initialize(x = nil, y = nil)
    init_screen
    curs_set(0)
    noecho
    x = cols if x.nil?
    y = lines if y.nil?
    starty = y.nil? ? 0 : (lines - y) / 2
    startx = x.nil? ? 0 : (cols - x) / 2
    @prim = Window.new(y, x, starty, startx)
    unless x == cols && y == lines
      @prim_border = Window.new(y + 2, x + 4, starty - 1, startx - 2)
    end
  end

  def clear_input_window
    @input_window.clear
    @input_window.box("|", "-")
    @input_window.refresh
  end

  def empty_window_with_title(title)
    empty_main
    draw_title(title)
  end

  def prompt_value(prompt)
    @input_window.setpos(@input_window.maxy / 2, 2)
    @input_window.addstr("#{prompt}: ")
    curs_set(1)
    echo
    @input_window.refresh
    value = @input_window.getstr
    noecho
    curs_set(0)
    hide_window(@input_window)
    return value.to_f if value == value.to_f.to_s || value == value.to_i.to_s
    nil
  end

  def choose_to?(prompt)
    clear_input_window
    @input_window.setpos(@input_window.maxy / 2, 2)
    @input_window.addstr("Press 'y' to #{prompt}: ")
    curs_set(1)
    echo
    @input_window.refresh
    val = @input_window.getch
    noecho
    curs_set(0)
    hide_window(@input_window)
    val.downcase == 'y'
  end

  def wait_for_key(prompt)
    clear_input_window
    @input_window.setpos(@input_window.maxy / 2, 2)
    @input_window.addstr(prompt)
    @input_window.refresh
    @input_window.getch
    hide_window(@input_window)
  end

  def animate_lines(chars, speed, cycle: false, update_each_segment: false)
    chars = chars.is_a?(Array) ?
      chars.flatten :
      chars.chars
    if cycle
      counter = 0
      chars.cycle do |ch|
        @main.setpos(counter, 0)
        @main.addstr((ch * WIDTH)[0..WIDTH - 1])
        @main.refresh
        counter += 1
        sleep(speed) if update_each_segment
        break if counter == @main.maxy
      end
    else
      chars.each do |ch|
        @main.setpos(counter, 0)
        @main.addstr((ch * WIDTH)[0..WIDTH - 1])
        @main.refresh
        counter += 1
        sleep(speed) if update_each_segment
        break if counter >= chars.length
      end
    end
    sleep(speed) unless update_each_segment
  end

  def animate_list(arr, speed = 0.25)
    arr.each.with_index do |s, i|
      @main.setpos(i + 2, 0) # set position to current option
      @main.addstr("#{i + 1}. #{s}") # write the name
      @main.refresh
      sleep speed
      break if i == HEIGHT
    end
    @main.refresh
  end

  def draw_message(message, alignment = :center, y_offset = 0)
    total_length = if message.is_a?(Array)
      message.collect(&:first).flatten.join.length
    else
      message.length
    end
    start_pos = case alignment
    when :left then 2
    when :right then WIDTH - total_length - 2
    when :center then (WIDTH / 2) - (total_length / 2)
    end
    @main.setpos((@main.maxy / 2) + y_offset, start_pos)
    if message.is_a?(Array)
      message.each do |m|
        @main.attrset(m.last)
        @main.addstr(m.first)
      end
    else
      @main.attrset(A_NORMAL)
      @main.addstr(message)

    end
    @main.refresh
    @main.attrset(A_NORMAL)
  end

  def draw_options(options)
    draw_options_window(options, nil)
    position = -1
    while (ch = @main.getch)
      # raise ch.inspect.to_s
      case ch
      when 'w' then
        position -= 1 # code for up key
      when 's' then
        position += 1
      when 10 then # code for return key
        break
      when 'q' then
        exit
      end
      position = options.length - 1 if position < 0
      position = 0 if position >= options.length
      draw_options_window(options, position)
    end
    return position unless options.first.is_a?(Hash)
    options[position].keys.first
  end

  def draw_options_window(options, selection_index)
    options.each.with_index do |s, i|
      @main.setpos(i + 2, 0) # set position to current option
      @main.attrset(i == selection_index ? A_STANDOUT : A_NORMAL) # highlight if it matches selection index
      if s.is_a?(Hash) then @main.addstr("#{i + 1}. #{s.values.first}"); next end
      @main.addstr(s)
    end
    @main.refresh
  end

  def draw_title(string)
    @main.setpos(0, 0)
    @main.addstr(" #{string} ".center(@main.maxx, '-'))
    @main.refresh
  end

  def hide_window(window)
    window.clear
    window.refresh
  end

  def empty_main
    @main_border.box("|", "-")
    @main.clear
    @main_border.refresh
    @main.refresh
  end
end
