require 'curses'
require 'csv'
require_relative 'station'
require_relative 'oyster_card'
include(Curses)

class App
  LOAD_SPEED = 0.002
  STATIONS = CSV.parse(File.read('./data/stations.csv')).drop(1).sort.map { |s| Station.new(s.first, s.last.to_i) }
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
    @main_window = Curses::Window.new(Curses.lines / 2 - 1, Curses.cols / 2 - 1, 0, 0)
    # @win2 = Curses::Window.new(3, Curses.cols / 2 - 1, Curses.lines / 2, 0)
    # @win3 = Curses::Window.new(3, Curses.cols / 2 - 1, Curses.lines / 2, 0)
    # @win4 = Curses::Window.new(3, Curses.cols / 2 - 1, (Curses.lines / 2) + 3, 0)
  end

  def run # main flow
    # show welcome window
    draw_empty_window(@main_window)
    # show welcome message
    draw_title(@main_window, 'Welcome to the Underground')
    sleep(0.1)
    # show a loading bar below welcome message
    boot_sequence(@main_window, 2, '#')
    boot_sequence(@main_window, 3, '*')
    boot_sequence(@main_window, 4, '$')
    boot_sequence(@main_window, 5, '#')
    boot_sequence(@main_window, 6, '*')
    boot_sequence(@main_window, 7, '$')
    boot_sequence(@main_window, 8, '#')
    boot_sequence(@main_window, 9, '*')
    boot_sequence(@main_window, 10, '$')
    boot_sequence(@main_window, 11, '#')
    boot_sequence(@main_window, 12, '*')
    boot_sequence(@main_window, 2, ' ')
    boot_sequence(@main_window, 3, ' ')
    boot_sequence(@main_window, 4, ' ')
    boot_sequence(@main_window, 5, ' ')
    boot_sequence(@main_window, 6, ' ')
    boot_sequence(@main_window, 7, ' ')
    boot_sequence(@main_window, 8, ' ')
    boot_sequence(@main_window, 9, ' ')
    boot_sequence(@main_window, 10, ' ')
    boot_sequence(@main_window, 11, ' ')
    boot_sequence(@main_window, 12, ' ')
    sleep(0.1)
    # clears window
    draw_empty_window(@main_window)
    # show options window with selection (this is the main loop)
    draw_title(@main_window, "Options (Use W/S to move, D to select)")
    loop do
      (option = draw_options(@main_window, OPTIONS))
      case option

      #   #   1. View Balance
      when :balance
        draw_empty_window(@main_window)
        draw_title(@main_window, 'SUCCESS!')
        sleep(2)
        #     draw_empty_window(@main_window)
        #     draw_balance(@main_window)

        #     #   2. Top Up
        #   when :topup
        #     #     1. Clears screen, shows current balance
        #     draw_empty_window(@main_window)
        #     draw_balance(@main_window)
        #     #     2. Asks for input 'how much?'
        #     1.times do
        #       case (value = try_top_up(@main_window))
        #     #        If input is invalid
        #     #        Shows error with (y/n) input option if invalid (amount or invalid characters)
        #       when nil # invalid characters
        #         #        -  Try again if yes else clear and return to options screen
        #         redo if try_again?(@main_window, 'Invalid Input: Please enter only numbers')
        #       when Numeric
        #         if value > OysterCard::MAX_BALANCE
        #           redo if try_again?(@main_window, 'Invalid Amount: Max balance of £90 exceeded')
        #           break
        #         end
        #       #        Tops up card
        #       #        - Shows new balance, waits, then clears and returns to options screen
        #       @card.top_up(value)
        #       draw_balance(@main_window)
        #       end
        #     end

        #     #   3. Show Journey History
        #   when :history
        #     draw_empty_window(@main_window)
        #     draw_title(@main_window, 'Journey History')
        #     #     1. Shows list of journeys
        #     #        Station names, journey costs, and distances
        #     draw_journeys(@main_window)

        #     #   4. Start Train Journey
        #   when :start then break
        #     #     1. Shows list of stations with selector
        #     #     2. After selecting one, shows it in new window
        #     #     3. After selecting second, shows it in new window
        #     #        1. Shows distance and cost of journey
        #     #        2. Asks if user wants to return to options or start journey
        #     #        - Returns to options menu if yes
        #     #        3. Shows 3-line train animation in new window
        #     #        - Shows string moving between two station names
        #     #        - Shows distance travelled and percentage complete (considering journey distance)
        #     #        - Shows smoke as series of animated unicode chars ['o', '○', '◯', 'O', '•', '‘', '˚', '˙', '', ''] starting from train position and staying at same position
        #     #          This can be done by adding index of train position to a hash,
        #     #          then each frame, go through each position in smoke string and check if that index exists in the hash
        #     #          if it does, set the current character to current train index - matched index, if it's out of range it means the smoke has cleared so print nothing
        #     #        4. Listens for hidden message
        #     #        -  If secret button is pressed, writes character (𓀠 or 웃) traversing backwards on track from train position
        #     #        - Waits until character hits edge then returns to options
        #     #        5. Shows 'Journey complete' message then updates log and balance and returns to options

        #     #   (5 Maybe). Show Map
        #   when :map then break
        #     #     1. Shows nice rendering of stations, maybe just a list, or something more interesting if I have time

        #     #   6. Quit
        #   when :quit then break
        #     #      Shows goodbye message
        #     draw_empty_window(@main_window)
        #     draw_title(@main_window, 'Goodbye!')
        #     sleep 1
        #     #      Quits
        #     close_screen
        #     exit
      end
    end
    close_screen
    exit
  end

  #   begin
  #     draw_empty_window(@main_window)
  #     @main_window.addstr("— Welcome to the underground —".center(@main_window.maxx - 2))
  #     ['o', '○', '◯', 'O', '•', '‘', '˚', '˙', '', ''].cycle do |s|
  #       draw_empty_window(@main_window)
  #       @main_window.setpos(1, 2)
  #       @main_window.addstr(s)
  #       @main_window.refresh
  #       sleep(0.3)
  #     end
  #     draw_menu_window(@main_window, nil)
  #     menu(@main_window)
  #   end
  #   begin # draw loading window
  #     draw_empty_window(@win2)
  #     2.upto(@win2.maxx - 3) do |i|
  #       @win2.setpos(@win2.maxy / 2, i)
  #       @win2 << "*"
  #       @win2.refresh
  #       sleep 0.015
  #     end
  #   rescue
  #     Curses.close_screen
  #   end
  #   update_test
  #   sleep(2)
  #   begin # draw input
  #     draw_empty_window(@win3)
  #     @win3.setpos(@win3.maxy / 2, 1)
  #     @win3.addstr("Input: ")
  #     curs_set(1)
  #     @win3.refresh
  #     echo
  #     @input = @win3.getstr
  #     noecho
  #     curs_set(0)
  #     sleep(0.1)
  #   end
  #   begin # draw output window
  #     draw_empty_window(@win4)
  #     @win4.setpos(@win4.maxy / 2, 1)
  #     @win4.addstr("You have input: #{@input}")
  #     @win4.refresh
  #     sleep(2)
  #   end
  # rescue
  #   close_screen
  # end

  #############################################################################################################################

  # def update_test
  #   # update first window with options
  #   @main_window.setpos(3, 1)
  #   @main_window.addstr("[ OPTIONS ]".center(@main_window.maxx - 2, '-'))
  #   @main_window.refresh
  #   sleep(0.5)
  # end

  # def draw_menu_window(window, selection_index = nil)
  #   @stations.each.with_index do |s, i|
  #     window.setpos(i + 1, 1) # set position to current station
  #     window.attrset(i == selection_index ? A_STANDOUT : A_NORMAL) # highlight if it matches selection index
  #     window.addstr(s.name) # write the name of the station
  #   end
  # end

  # def menu(window)
  #   position = -1
  #   while (ch = window.getch)
  #     case ch
  #     when 'w' then position -= 1
  #     when 's' then position += 1
  #     when 'd' then break
  #     when 'q' then exit
  #     end
  #     position = @stations.length - 1 if position < 0
  #     position = 0 if position >= @stations.length
  #     draw_menu_window(window, position)
  #   end
  #   position
  # end

  #############################################################################################################################

  def boot_sequence(window, y_pos, char)
    window.setpos(y_pos, 2)
    2.upto(window.maxx - 3) do |i|
      window.setpos(y_pos, i)
      window << char
      window.refresh
      sleep LOAD_SPEED
    end
  end

  def draw_options(window, options)
    draw_options_window(window, options, nil)
    position = -1
    while (ch = window.getch)
      case ch
      when 'w' then position -= 1
      when 's' then position += 1
      when 'd' then break
      when 'q' then exit
      end
      position = options.length - 1 if position < 0
      position = 0 if position >= options.length
      draw_options_window(window, options, position)
    end
    options[position].keys.first
  end

  def draw_options_window(window, options, selection_index)
    options.each.with_index do |s, i|
      window.setpos(i + 3, 2) # set position to current option
      window.attrset(i == selection_index ? A_STANDOUT : A_NORMAL) # highlight if it matches selection index
      window.addstr("#{i + 1}. #{s.values.first}") # write the name
    end
    window.refresh
  end

  # pure window stuff that can maybe be a module?

  def draw_empty_window(window)
    window.clear
    window.box("|", "-")
    window.setpos(1, 1)
    window.refresh
  end

  def draw_title(window, string)
    window.setpos(1, 2)
    window.addstr(" #{string} ".center(window.maxx - 4, '—'))
    window.refresh
  end
end

app = App.new
app.run

################# JUNK YARD #################

# class Interface
#   STATIONS_PATH = "./data/stations.csv"

#   def initialize
#     @stations = CSV.parse(File.read(STATIONS_PATH)).drop(1).map { |s| Station.new(s.first, s.last.to_i) }
#     @card = OysterCard.new
#   end

#   def run
#     Display.draw("Welcome to the London Underground.")
#     sleep(0.5)
#     loop do
#       options
#       Display.newline
#       input
#     end
#   end

#   def options
#     gets.chomp
#     Display.newline
#     Display.draw("Here are your options:")
#     Display.draw_list(
#       ["1. Top up oyster",
#        "2. Check balance",
#        "3. Show map",
#        "4. Take train",
#        "5. Quit"]
#     )
#   end

#   def input
#     case Display.prompt("Input: ")
#     when "1" then top_up
#     when "2" then balance
#     when "3" then stations
#     when "4" then train_journey
#     when "5" then exit
#     end
#   end

#   def top_up
#     Display.newline
#     @card.top_up(Display.prompt("Top up amount: ").to_i)
#     balance
#   end

#   def balance
#     Display.newline
#     Display.puts("Your balance is currently £#{@card.balance}")
#   end

#   def stations
#     Display.newline
#     Display.draw("All Stations:")
#     @stations.each { |s| Display.draw("#{s.name} — Zone #{s.zone}") }
#   end

#   def train_journey
#     a = search_stations(Display.prompt("Start at: "))
#     if a.is_a?(String)
#       Display.puts("No station with name '#{a}' found.")
#       return
#     end
#     b = search_stations(Display.prompt("End at: "))
#     if b.is_a?(String)
#       Display.puts("No station with name '#{b}' found.")
#       return
#     end
#     Display.animate_train(a.name, b.name, 20)
#     Display.newline
#     Display.draw("Arrived at #{b.name}")
#   end

#   def search_stations(input)
#     @stations.each do |s|
#       return s if s.name.downcase.start_with?(input.downcase)
#     end
#     input
#   end
#  #end
