require 'curses'
require 'csv'
require_relative 'station'
require_relative 'oyster_card'
require_relative 'clui'
include(Curses)

class App
  LOAD_SPEED = 0.001
  STATIONS = CSV.parse(File.read('./data/stations.csv')).drop(1).sort.map { |s| Station.new(s.first, s.last.to_i) }
  HEIGHT = 26
  WIDTH = 100
  TRAIN = '[____]'
  SMOKE = ['o', '○', '◯', 'O', '•', '‘', '˚', '˙', '', '']
  SMOKE_OFFSET = 2
  TRAIN_TIME = 0.1
  OPTIONS = [
    { balance: 'View Balance' },
    { topup: 'Top Up' },
    { history: 'Show Journey History' },
    { start: 'Start Train Journey' },
    { map: 'Show Stations' },
    { quit: 'Quit' },
  ]

  def initialize
    init_screen
    cbreak
    stdscr.keypad = 1
    curs_set(0)
    noecho
    @card = OysterCard.new
    starty = (lines - HEIGHT) / 2
    startx = (cols - WIDTH) / 2
    @main = Window.new(HEIGHT, WIDTH, starty, startx)
    @input_window = Curses::Window.new(3, WIDTH, (Curses.lines / 2 - HEIGHT / 2) + HEIGHT, Curses.cols / 2 - WIDTH / 2)
  end

  def run # main flow
    startup
    main_loop
  end

  def startup
    # show welcome window
    empty_window(@main)
    ## show welcome message
    draw_title('Welcome to the Underground')
    ## show a loading bar below welcome message
    animate_lines(['O', 'o', '•', '‘', '˚', '˙', '˙', '˚', '‘', '•', 'o'], 0.1, cycle: true)
    empty_window(@main)
  end

  def main_loop
    loop do
      @main.attrset(A_NORMAL)
      empty_window(@main)
      draw_title("Options (Use W/S to move, Enter to select)")
      option = draw_options(OPTIONS)
      case option
      when :balance then balance
      when :topup then top_up
      when :history then history
      when :start then start
      when :map then map
      when :quit then quit
      end
    end
  end

  ############## OPTIONS ##############

  def balance
    empty_window(@main)
    draw_title('Current Balance')
    draw_message("Account has £#{@card.balance} and a max balance of £#{OysterCard::MAX_BALANCE}")
    wait_for_key("Press any key.")
  end

  def top_up
    value = 0
    1.times do
      empty_window(@main)
      draw_title('Please Enter Top-Up Amount')
      draw_message("Account currently has £#{@card.balance}")
      # 2. Asks for input 'how much?'
      value = prompt_value("Enter Amount")
      if value.nil?
        redo if decide?('Invalid Input, only use valid numbers', "Try again? (y/n): ")
        return
      end
      if @card.balance + value > OysterCard::MAX_BALANCE
        draw_title("Max balance reached, adding £#{OysterCard::MAX_BALANCE - @card.balance}")
        @card.top_up(OysterCard::MAX_BALANCE - @card.balance)
        sleep(2)
        break
      end
      @card.top_up(value)
    end
    hide_window(@input_window)
    empty_window(@main)
    draw_title('Balance')
    draw_message("Account now has £#{@card.balance}")
    sleep(2)
  end

  def history
    empty_window(@main)
    draw_title("Journey History")
    if @card.journey_log.history.empty?
      draw_message("No history yet", A_STANDOUT)
      wait_for_key("Press any key.")
      return
    end
    history = @card.journey_log.history.map { |s| "#{s.entry_station.name} to #{s.exit_station.name} — £#{s.fare}, #{(s.entry_station.zone - s.exit_station.zone).abs + 1 * 3}km" }
    animate_list(history)
    wait_for_key("Press any key.")
  end

  def start
    smoke_indeces = []
    pos = 0
    empty_window(@main)
    draw_title('Select start and end stations')
    option1 = draw_options(STATIONS.map { |s| "#{s.name} - Z#{s.zone}" })
    empty_window(@input_window)
    @input_window.setpos(@input_window.maxy / 2, 2)
    @input_window.addstr("[#{STATIONS[option1].name}]")
    @input_window.refresh
    option2 = draw_options(STATIONS.map { |s| "#{s.name} - Z#{s.zone}" })
    @input_window.setpos(@input_window.maxy / 2, 2)
    @input_window.addstr("[#{STATIONS[option2].name}]".rjust(WIDTH - 4))
    @input_window.setpos(@input_window.maxy / 2, 2)
    @input_window.addstr("[#{STATIONS[option1].name}]")
    @input_window.refresh
    sleep(1)
    hide_window(@input_window)
    @main.clear
    @main.refresh
    @main.setpos((@main.maxy / 2) + 1, 0)
    @main.addstr("[#{STATIONS[option1].name}]#{'=' * (WIDTH - STATIONS[option1].name.length - STATIONS[option2].name.length - 4)}[#{STATIONS[option2].name}]".center(WIDTH, "@"))
    @main.refresh
    sleep(1)
    loop do
      @main.setpos((@main.maxy / 2) + 2, 0)
      @main.addstr("Travelled %#{((pos / WIDTH) * 100)}".center(WIDTH))
      @main.setpos((@main.maxy / 2), 0)
      @main.addstr(" " * WIDTH)
      @main.setpos((@main.maxy / 2), pos)
      @main.addstr(TRAIN)

      pos += 1
      smoke_indeces << pos if [false, false, true].sample
      @main.setpos((@main.maxy / 2) - 1, 0)
      @main.addstr(" " * WIDTH)
      smoke_indeces.each do |i|
        @main.setpos((@main.maxy / 2) - 1, i + SMOKE_OFFSET)
        @main.addstr(" ")
        unless SMOKE[pos - i].nil?
          @main.addstr(SMOKE[pos - i])
        end
      end
      @main.refresh
      sleep TRAIN_TIME
      if pos > WIDTH - TRAIN.length then sleep(0.5); break end
    end
    #        4. Listens for hidden message
    #        -  If secret button is pressed, writes character (𓀠 or 웃) traversing backwards on track from train position
    #        - Waits until character hits edge then returns to options
    #        5. Shows 'Journey complete' message then updates log and balance and returns to options
    @card.journey_log.start(STATIONS[option1])
    @card.journey_log.finish(STATIONS[option2])
  end

  def map
    empty_window(@main)
    draw_title("All Stations")
    stations_list = STATIONS.map { |s| "#{s.name} - Zone #{s.zone}" }
    animate_list(stations_list)
    wait_for_key("Press any key.")
  end

  def quit
    empty_window(@main)
    draw_message('Goodbye!')
    sleep(1)
    close_screen
    exit
  end

  ############## UTILITY METHODS ##############

  def draw_empty_titled_window(title)
    empty_window(@main)
    draw_title(title)
  end

  def prompt_value(prompt)
    empty_window(@input_window)
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

  def choice?(prompt)
    empty_window(@input_window)
    @input_window.setpos(@input_window.maxy / 2, 2)
    @input_window.addstr(prompt)
    curs_set(1)
    echo
    @input_window.refresh
    value = @input_window.getch.downcase == 'y'
    noecho
    curs_set(0)
    hide_window(@input_window)
    value
  end

  def wait_for_key(prompt)
    empty_window(@input_window)
    @input_window.setpos(@input_window.maxy / 2, 2)
    @input_window.addstr(prompt)
    @input_window.refresh
    @input_window.getch
    hide_window(@input_window)
  end

  def animate_lines(chars, speed, cycle: false)
    offset = 2
    if cycle
      counter = offset
      chars.cycle do |ch|
        @main.setpos(counter, 2)
        @main.addstr(ch * (WIDTH - 4))
        @main.refresh
        counter += 1
        sleep speed
        break if counter > @main.maxy - 2
      end
    else
      chars.each do |ch|
        @main.setpos(counter, 1)
        @main.addstr(ch * (WIDTH - 4))
        @main.refresh
        counter += 1
        sleep speed
        break if counter >= chars.length
      end
    end
    sleep(1)
  end

  def animate_list(arr, speed = 0.25)
    arr.each.with_index do |s, i|
      @main.setpos(i + 3, 2) # set position to current option
      @main.addstr("#{i + 1}. #{s}") # write the name
      @main.refresh
      sleep speed
      break if i >= HEIGHT - 4
    end
    @main.refresh
  end

  def draw_message(message, style = A_STANDOUT)
    padding = 8
    @main.setpos(@main.maxy / 2, 8)
    @main.attrset(style)
    @main.addstr(message.center(@main.maxx - (padding * 2)))
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
      @main.setpos(i + 3, 2) # set position to current option
      @main.attrset(i == selection_index ? A_STANDOUT : A_NORMAL) # highlight if it matches selection index
      if s.is_a?(Hash) then @main.addstr("#{i + 1}. #{s.values.first}"); next end
      @main.addstr(s)
    end
    @main.refresh
  end

  def empty_window(window)
    window.attrset(A_NORMAL)
    window.clear
    window.box("|", "-")
    window.setpos(1, 1)
    window.refresh
  end

  def draw_title(string)
    @main.setpos(1, 2)
    @main.addstr(" #{string} ".center(@main.maxx - 4, '—'))
    @main.refresh
  end

  def hide_window(window)
    window.clear
    window.refresh
  end
end

app = App.new
app.run
