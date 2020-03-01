require 'curses'
require 'csv'
require_relative 'station'
require_relative 'oyster_card'
require_relative 'clui'
include(Curses)

# note: this gets me right justified position (accounting for border, new ui shouldn't need the -2)
# WIDTH - message.length - 2
class App
  TEMPO = 89/240r
  # TEMPO = 0.196666667
  STATIONS = CSV.parse(File.read('./data/stations.csv')).drop(1).sort.map { |s| Station.new(s.first, s.last.to_i) }
  HEIGHT = 26
  WIDTH = 106
  TRAIN = '[ニニ]'
  SMOKE = ['o', '○', '◯', 'O', '•', '‘', '˚', '˙', '', '']
  TRAIN_TIME = 0.1
  OPTIONS = [
    { balance: 'View Balance' },
    { top_up: 'Top Up' },
    { stations: 'Show Stations' },
    { history: 'Show Journey History' },
    { start_journey: 'Start Train Journey' },
    { quit: 'Quit' },
  ]

  def initialize
    init_screen
    curs_set(0)
    noecho
    @card = OysterCard.new
    starty = (lines - HEIGHT) / 2
    startx = (cols - WIDTH) / 2
    @main = Window.new(HEIGHT, WIDTH, starty, startx)
    @main_border = Window.new(HEIGHT + 2, WIDTH + 4, starty - 1, startx - 2)
    @input_window = Curses::Window.new(3, WIDTH + 4, (Curses.lines / 2 - HEIGHT / 2) + HEIGHT + 1, (Curses.cols / 2 - WIDTH / 2) - 2)
  end

  def run # main flow
    startup
    main_loop
  end

  def startup
    empty_main

    animate_lines(['• # •'], TEMPO / 8, cycle: true, update_each_segment: true)
    messaage = 'Welcome to the Underground'
    draw_message(' ' * (messaage.length + 3), A_NORMAL, :center, 1)
    draw_message(' ' * (messaage.length + 3), A_NORMAL, :center, 0)
    draw_message(' ' * (messaage.length + 3), A_NORMAL, :center, -1)
    draw_message('Welcome to the Underground', A_NORMAL)
    sleep(2)
    animate_lines(' ··•○•·· ', TEMPO / 4, cycle: true)
    animate_lines('  ··•··  ', TEMPO / 4, cycle: true)
    animate_lines('   ···   ', TEMPO / 4, cycle: true)
    animate_lines('    ·    ', TEMPO / 4, cycle: true)

    empty_main
  end

  def main_loop
    loop do
      @main.attrset(A_NORMAL)
      empty_main
      draw_title("Options (Use W/S to move, Enter to select)")
      option = draw_options(OPTIONS)
      case option
      when :balance then balance
      when :top_up then top_up
      when :history then history
      when :start_journey then start_journey
      when :stations then stations
      when :quit then quit
      end
    end
  end

  def format_balance
    '%.2f' % @card.balance
  end

  ############## OPTIONS ##############

  def balance
    empty_main
    draw_title('Current Balance')
    draw_message("Account has £#{format_balance} and a max balance of £#{OysterCard::MAX_BALANCE}")
    wait_for_key("Press any key.")
  end

  def top_up
    empty_window_with_title('Please Enter Top-Up Amount')
    draw_message("Account currently has £#{format_balance}")
    clear_input_window
    value = 0
    1.times do
      value = prompt_value("Enter Amount")
      if value.nil?
        draw_message('Invalid Input, only use valid numbers')
        redo if choose_to?('try again')
        return
      end
      if @card.balance + value > OysterCard::MAX_BALANCE
        draw_title("Max balance reached, adding £#{format('%.2f', (OysterCard::MAX_BALANCE - @card.balance))}")
        @card.top_up(OysterCard::MAX_BALANCE - @card.balance)
        sleep(2)
        break
      end
      @card.top_up(value)
    end
    hide_window(@input_window)
    empty_window_with_title('Balance')
    draw_message("Account now has £#{format_balance}")
    sleep(2)
  end

  def history
    empty_window_with_title('Journey History')
    if @card.journey_log.history.empty?
      draw_message("No history yet", A_STANDOUT)
      wait_for_key("Press any key.")
      return
    end
    history = @card.journey_log.history.map { |s| "#{s.entry_station.name} to #{s.exit_station.name} — £#{s.fare}, #{(s.entry_station.zone - s.exit_station.zone).abs + 1 * 3}km" }
    animate_list(history)
    wait_for_key("Press any key.")
  end

  def start_journey
    if @card.balance < OysterCard::MIN_BALANCE
      empty_window_with_title('Balance too low to travel')
      draw_message('Please Top Up')
      sleep(3)
      return
    end
    empty_window_with_title('Select START and END stations')
    option1 = draw_options(STATIONS.map { |s| "#{s.name} - Z#{s.zone}" })
    clear_input_window
    @input_window.setpos(@input_window.maxy / 2, 1)
    @input_window.addstr("[#{STATIONS[option1].name}]")
    @input_window.refresh
    option2 = draw_options(STATIONS.map { |s| "#{s.name} - Z#{s.zone}" })
    @input_window.setpos(@input_window.maxy / 2, 1)
    @input_window.addstr("[#{STATIONS[option2].name}]".rjust(WIDTH + 2))
    @input_window.setpos(@input_window.maxy / 2, 1)
    @input_window.addstr("[#{STATIONS[option1].name}]")
    @input_window.refresh
    sleep(1)
    hide_window(@input_window)
    hide_window(@main_border)
    @main.clear
    @main.refresh
    @main.setpos((@main.maxy / 2) + 1, 0)
    @main.addstr("[#{STATIONS[option1].name}]#{'=' * (WIDTH - STATIONS[option1].name.length - 4 - STATIONS[option2].name.length)}[#{STATIONS[option2].name}]".center(WIDTH))
    @main.refresh
    sleep(1)
    @card.touch_in(STATIONS[option1])

    smoke_indeces = []
    pos = 0
    loop do # animate train
      @main.setpos((@main.maxy / 2) + 2, 0)
      @main.addstr("Travelled #{pos.percent_of(WIDTH - TRAIN.length).to_i}%".center(WIDTH))
      @main.setpos((@main.maxy / 2), 0)
      @main.addstr(" " * WIDTH)
      @main.setpos((@main.maxy / 2), pos)
      @main.addstr(TRAIN)
      pos += 1
      smoke_indeces << pos if [false, false, true].sample
      @main.setpos((@main.maxy / 2) - 1, 0)
      @main.delch
      smoke_indeces.each do |i|
        @main.setpos((@main.maxy / 2) - 1, i + TRAIN.length - 1)
        @main.addstr(" ")
        unless SMOKE[pos - i].nil?
          @main.addstr(SMOKE[pos - i])
        end
      end
      @main.refresh
      sleep TRAIN_TIME
      if pos > WIDTH - TRAIN.length - 2 then sleep(0.5); break end
    end
    @card.touch_out(STATIONS[option2])
  end

  def stations
    empty_window_with_title('All Stations')
    stations_list = STATIONS.map { |s| "#{s.name} - Zone #{s.zone}" }
    animate_list(stations_list)
    wait_for_key("Press any key.")
  end

  def quit
    empty_main
    draw_message('Goodbye!')
    sleep(1)
    close_screen
    exit
  end

  ############## UTILITY METHODS ##############

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

  def draw_message(message, style = A_STANDOUT, alignment = :center, y_offset = 0)
    pos = case alignment
    when :left then 2
    when :right then WIDTH - message.length - 2
    when :center then (WIDTH / 2) - (message.length / 2)
    end
    @main.setpos((@main.maxy / 2) + y_offset, pos)
    @main.attrset(style)
    @main.addstr(message)
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

class Numeric
  def percent_of(n)
    to_f / n.to_f * 100.0
  end
end

app = App.new
app.run
