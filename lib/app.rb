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
    @ui = CLUI.new(WIDTH, HEIGHT)
    @ui.sequence_y(SMOKE, type: :wipe, cycle: true)
    @card = OysterCard.new
    @input_window = Curses::Window.new(3, WIDTH, (Curses.lines / 2 - HEIGHT / 2) + HEIGHT, Curses.cols / 2 - WIDTH / 2)
  end

  def run # main flow
    startup
    main_loop
  end

  def startup
    # show welcome window
    empty_window(@ui.prim)
    ## show welcome message
    draw_title('Welcome to the Underground')
    sleep(0.5)
    ## show a loading bar below welcome message
    animate_lines(['O', '◯', 'o', '•', '‘', '˚', '˙', '', ''], false)
    empty_window(@ui.prim)
  end

  def main_loop
    @ui.prim.attrset(A_NORMAL)
    empty_window(@ui.prim)
    draw_title("Options (Use W/S to move, D to select)")
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

  ############## OPTIONS ##############

  def balance
    empty_window(@ui.prim)
    draw_title('Current Balance')
    draw_message("Account has £#{@card.balance} and a max balance of £#{OysterCard::MAX_BALANCE}")
    sleep(2)
    main_loop
  end

  def top_up
    value = 0
    1.times do
      empty_window(@ui.prim)
      draw_title('Please Enter Top-Up Amount')
      draw_message("Account currently has £#{@card.balance}")
      # 2. Asks for input 'how much?'
      value = prompt_value("Enter Amount")
      if value.nil?
        redo if try_again?('Invalid Input, only use valid numbers', "Try again? (y/n): ")
        break
      end
      if @card.balance + value > OysterCard::MAX_BALANCE
        draw_title("Max balance reached, adding £#{OysterCard::MAX_BALANCE - @card.balance}")
        sleep(2)
        @card.top_up(OysterCard::MAX_BALANCE - @card.balance)
      end
      @card.top_up(value)
    end
    hide_window(@input_window)
    empty_window(@ui.prim)
    draw_title('Balance')
    draw_message("Account now has £#{@card.balance}")
    sleep(2)
    main_loop
  end

  def history
    empty_window(@ui.prim)
    draw_title("Journey History")
    if @card.journey_log.history.empty?
      draw_message("No history yet", A_STANDOUT)
      main_loop if try_again?(nil, "Return to options? (y/n): ")
    end
    history = @card.journey_log.history.map { |s| "#{s.entry_station.name} to #{s.exit_station.name} — £#{s.fare}, #{(s.entry_station.zone - s.exit_station.zone).abs + 1 * 3}km" }
    animate_list(history)
    main_loop if try_again?(nil, "Return to options? (y/n): ")
  end

  def start
    smoke_indeces = []
    pos = 0
    #     1. Shows list of stations with selector
    empty_window(@ui.prim)
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
    @ui.prim.clear
    @ui.prim.refresh
    @ui.prim.setpos((@ui.prim.maxy / 2) + 1, 0)
    @ui.prim.addstr("[#{STATIONS[option1].name}]#{'=' * (WIDTH - STATIONS[option1].name.length - STATIONS[option2].name.length - 4)}[#{STATIONS[option2].name}]".center(WIDTH, "@"))
    @ui.prim.refresh
    sleep(1)
    loop do
      @ui.prim.setpos((@ui.prim.maxy / 2) + 2, 0)
      @ui.prim.addstr("Travelled %#{((pos / WIDTH) * 100)}".center(WIDTH))
      @ui.prim.setpos((@ui.prim.maxy / 2), 0)
      @ui.prim.addstr(" " * WIDTH)
      @ui.prim.setpos((@ui.prim.maxy / 2), pos)
      @ui.prim.addstr(TRAIN)

      pos += 1
      smoke_indeces << pos if [false, false, true].sample
      @ui.prim.setpos((@ui.prim.maxy / 2) - 1, 0)
      @ui.prim.addstr(" " * WIDTH)
      smoke_indeces.each do |i|
        @ui.prim.setpos((@ui.prim.maxy / 2) - 1, i + SMOKE_OFFSET)
        @ui.prim.addstr(" ")
        unless SMOKE[pos - i].nil?
          @ui.prim.addstr(SMOKE[pos - i])
        end
      end
      @ui.prim.refresh
      sleep TRAIN_TIME
      if pos > WIDTH - TRAIN.length then sleep(0.5); break end
    end
    #        4. Listens for hidden message
    #        -  If secret button is pressed, writes character (𓀠 or 웃) traversing backwards on track from train position
    #        - Waits until character hits edge then returns to options
    #        5. Shows 'Journey complete' message then updates log and balance and returns to options
    @card.journey_log.start(STATIONS[option1])
    @card.journey_log.finish(STATIONS[option2])
    main_loop
  end

  def map
    empty_window(@ui.prim)
    draw_title("All Stations")
    stations_list = STATIONS.map { |s| "#{s.name} - Zone #{s.zone}" }
    animate_list(stations_list)
    main_loop if try_again?(nil, "Return to options? (y/n): ")
  end

  def quit
    empty_window(@ui.prim)
    draw_message('Goodbye!')
    sleep(1)
    close_screen
    exit
  end

  ############## UTILITY METHODS ##############

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

  def try_again?(message, prompt)
    empty_window(@input_window)
    draw_message(message) unless message.nil?
    @input_window.setpos(@input_window.maxy / 2, 2)
    @input_window.addstr(prompt)
    curs_set(1)
    echo
    @input_window.refresh
    value = @input_window.getch
    noecho
    curs_set(0)
    hide_window(@input_window)
    return true if value.downcase == 'y'
    return false if value.downcase == 'n'
  end

  def animate_lines(chars, cycle = false)
    offset = 2
    if cycle
      counter = offset
      chars.cycle do |ch|
        return if counter > @ui.prim.maxy - 2
        2.upto(@ui.prim.maxx - 3) do |i|
          @ui.prim.setpos(counter, i)
          @ui.prim << ch
          @ui.prim.refresh
          sleep LOAD_SPEED
        end
        counter += 1
      end
    else
      chars.length.times do |line|
        2.upto(@ui.prim.maxx - 3) do |i|
          @ui.prim.setpos(line + offset, i)
          char = chars[line].nil? ? ' ' : chars[line]
          @ui.prim << char
          @ui.prim.refresh
          sleep LOAD_SPEED
        end
      end
    end
  end

  def animate_list(arr)
    arr.each.with_index do |s, i|
      @ui.prim.setpos(i + 3, 2) # set position to current option
      @ui.prim.addstr("#{i + 1}. #{s}") # write the name
      @ui.prim.refresh
      sleep 0.3
      break if i >= HEIGHT - 4
    end
    @ui.prim.refresh
  end

  def draw_message(message, style = A_STANDOUT)
    padding = 8
    @ui.prim.setpos(@ui.prim.maxy / 2, 8)
    @ui.prim.attrset(style)
    @ui.prim.addstr(message.center(@ui.prim.maxx - (padding * 2)))
    @ui.prim.refresh
    @ui.prim.attrset(A_NORMAL)
  end

  def draw_options(options)
    draw_options_window(options, nil)
    position = -1
    while (ch = @ui.prim.getch)
      case ch
      when 'w' then position -= 1
      when 's' then position += 1
      when 'd' then break
      when 'q' then exit
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
      @ui.prim.setpos(i + 3, 2) # set position to current option
      @ui.prim.attrset(i == selection_index ? A_STANDOUT : A_NORMAL) # highlight if it matches selection index
      if s.is_a?(Hash) then @ui.prim.addstr("#{i + 1}. #{s.values.first}"); next end
      @ui.prim.addstr(s)
    end
    @ui.prim.refresh
  end

  def empty_window(window)
    window.attrset(A_NORMAL)
    window.clear
    window.box("|", "-")
    window.setpos(1, 1)
    window.refresh
  end

  def draw_title(string)
    @ui.prim.setpos(1, 2)
    @ui.prim.addstr(" #{string} ".center(@ui.prim.maxx - 4, '—'))
    @ui.prim.refresh
  end

  def hide_window(window)
    window.clear
    window.refresh
  end
end

app = App.new
app.run
