require 'curses'
require 'csv'
require_relative 'station'
require_relative 'oyster_card'
include(Curses)

class App
  LOAD_SPEED = 0.001
  STATIONS = CSV.parse(File.read('./data/stations.csv')).drop(1).sort.map { |s| Station.new(s.first, s.last.to_i) }
  HEIGHT = 26
  WIDTH = 100
  OPTIONS = [
    { balance: 'View Balance' },
    { topup: 'Top Up' },
    { history: 'Show Journey History' },
    { start: 'Start Train Journey' },
    { map: 'Show Map' },
    { quit: 'Quit' },
  ]

  def initialize
    # Get all stations from stations.csv file and create new station object for each one
    init_screen # start curses
    curs_set(0) # hide cursor
    noecho # dont echo all input straight away
    @card = OysterCard.new
    @main_window = Curses::Window.new(HEIGHT, WIDTH, Curses.lines / 2 - HEIGHT / 2, Curses.cols / 2 - WIDTH / 2)
    @input_window = Curses::Window.new(3, WIDTH, (Curses.lines / 2 - HEIGHT / 2) + HEIGHT, Curses.cols / 2 - WIDTH / 2)
  end

  def run # main flow
    startup
    main_loop
  end

  def startup
    # show welcome window
    empty_window(@main_window)
    # show welcome message
    draw_title('Welcome to the Underground')
    sleep(0.1)
    # show a loading bar below welcome message
    animate_lines(['O', '◯', 'o', '•', '‘', '˚', '˙', '', ''], false)
    # animate_lines([' '], true)
    empty_window(@main_window)
  end

  def main_loop
    @main_window.attrset(A_NORMAL)
    empty_window(@main_window)
    draw_title("Options (Use W/S to move, D to select)")
    option = draw_options(OPTIONS)
    case option
    when :balance then balance
    when :topup then top_up
    when :start then start
    when :quit then quit
    end
  end

  ############## OPTIONS ##############

  def balance
    empty_window(@main_window)
    draw_title('Current Balance')
    draw_message("Account has £#{@card.balance} and a max balance of £#{OysterCard::MAX_BALANCE}")
    sleep(2)
    main_loop
  end

  def top_up
    # 1. Clears screen, shows current balance
    1.times do
      empty_window(@main_window)
      draw_title('Please Enter Top-Up Amount')
      draw_message("Account currently has £#{@card.balance}")
      # 2. Asks for input 'how much?'
      begin
        value = prompt_value("Enter Amount")
      rescue
        draw_message("RESCUED!!!")
        sleep(2)
        redo if try_again?('Invalid Amount: Max balance of £90 exceeded')
      end
      if value.nil?
        redo if try_again?('Invalid Input, please try again')
      end
      #        Tops up card
      hide_window(@input_window)
      @card.top_up(value)
      empty_window(@main_window)
      draw_message("Account now has £#{@card.balance}")
      sleep(2)
    end
    main_loop
  end

  def history
  end

  def start
    #     1. Shows list of stations with selector
    #     2. After selecting one, shows it in new window
    #     3. After selecting second, shows it in new window
    #        1. Shows distance and cost of journey
    #        2. Asks if user wants to return to options or start journey
    #        - Returns to options menu if yes
    #        3. Shows 3-line train animation in new window
    #        - Shows string moving between two station names
    #        - Shows distance travelled and percentage complete (considering journey distance)
    #        - Shows smoke as series of animated unicode chars ['o', '○', '◯', 'O', '•', '‘', '˚', '˙', '', ''] starting from train position and staying at same position
    #          This can be done by adding index of train position to a hash,
    #          then each frame, go through each position in smoke string and check if that index exists in the hash
    #          if it does, set the current character to current train index - matched index, if it's out of range it means the smoke has cleared so print nothing
    #        4. Listens for hidden message
    #        -  If secret button is pressed, writes character (𓀠 or 웃) traversing backwards on track from train position
    #        - Waits until character hits edge then returns to options
    #        5. Shows 'Journey complete' message then updates log and balance and returns to options
  end

  def quit
    empty_window(@main_window)
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
    value.to_i
  end

  def animate_lines(chars, cycle = false)
    offset = 2
    if cycle
      counter = offset
      chars.cycle do |ch|
        return if counter > @main_window.maxy - 2
        2.upto(@main_window.maxx - 3) do |i|
          @main_window.setpos(counter, i)
          @main_window << ch
          @main_window.refresh
          sleep LOAD_SPEED
        end
        counter += 1
      end
    else
      chars.length.times do |line|
        2.upto(@main_window.maxx - 3) do |i|
          @main_window.setpos(line + offset, i)
          char = chars[line].nil? ? ' ' : chars[line]
          @main_window << char
          @main_window.refresh
          sleep LOAD_SPEED
        end
      end
    end
  end

  def draw_message(message, style = A_STANDOUT)
    padding = 8
    @main_window.setpos(@main_window.maxy / 2, 8)
    @main_window.attrset(style)
    @main_window.addstr(message.center(@main_window.maxx - (padding * 2)))
    @main_window.refresh
    @main_window.attrset(A_NORMAL)
  end

  def draw_options(options)
    draw_options_window(options, nil)
    position = -1
    while (ch = @main_window.getch)
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
    options[position].keys.first
  end

  def draw_options_window(options, selection_index)
    options.each.with_index do |s, i|
      @main_window.setpos(i + 3, 2) # set position to current option
      @main_window.attrset(i == selection_index ? A_STANDOUT : A_NORMAL) # highlight if it matches selection index
      @main_window.addstr("#{i + 1}. #{s.values.first}") # write the name
    end
    @main_window.refresh
  end

  def empty_window(window)
    window.attrset(A_NORMAL)
    window.clear
    window.box("|", "-")
    window.setpos(1, 1)
    window.refresh
  end

  def draw_title(string)
    @main_window.setpos(1, 2)
    @main_window.addstr(" #{string} ".center(@main_window.maxx - 4, '—'))
    @main_window.refresh
  end

  def hide_window(window)
    window.clear
    window.refresh
  end
end

app = App.new
app.run
