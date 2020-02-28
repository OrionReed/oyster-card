require "curses"
require 'csv'
require_relative '../station'
include(Curses)

class App
  # Get all stations from stations.csv file and create new station object for each one
  def initialize
    @stations = CSV.parse(File.read('./data/stations.csv')).drop(1).sort.map { |s| Station.new(s.first, s.last.to_i) }
    init_screen # start curses
    curs_set(0) # hide cursor
    noecho # dont echo all input straight away
    @win1 = Curses::Window.new(Curses.lines / 2 - 1, Curses.cols / 2 - 1, 0, 0)
    @win2 = Curses::Window.new(3, Curses.cols / 2 - 1, Curses.lines / 2, 0)
    @win3 = Curses::Window.new(3, Curses.cols / 2 - 1, Curses.lines / 2, 0)
    @win4 = Curses::Window.new(3, Curses.cols / 2 - 1, (Curses.lines / 2) + 3, 0)
  end

  def run # main flow
    begin # draw main window
      # show welcome window
      # show welcome message
      # show a loading bar below welcome message
      # clears window
      # show options window with selection (this is the main loop)
      #   1. View Balance
      #   2. Top Up
      #     1. Clears screen, shows current balance
      #     2. Asks for input 'how much?'
      #        If input is invalid
      #        Shows error with (y/n) input option if invalid (amount or invalid characters)
      #        -  Try again if yes else clear and return to options screen
      #        Tops up card
      #        - Shows new balance, waits, then clears and returns to options screen
      #   3. Show Journey History
      #     1. Shows list of journeys
      #        Station names, journey costs, and distances
      #   4. Start Train Journey
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
      #   (5 Maybe). Show Map
      #     1. Shows nice rendering of stations, maybe just a list, or something more interesting if I have time
      #   6. Quit
      #      Shows goodbye message
      #      Quits

    end
    begin
      draw_empty_window(@win1)
      @win1.addstr("— Welcome to the underground —".center(@win1.maxx - 2))
      ['o', '○', '◯', 'O', '•', '‘', '˚', '˙', '', ''].cycle do |s|
        draw_empty_window(@win1)
        @win1.setpos(1, 2)
        @win1.addstr(s)
        @win1.refresh
        sleep(0.3)
      end
      draw_menu_window(@win1, nil)
      menu(@win1)
    end
    begin # draw loading window
      draw_empty_window(@win2)
      2.upto(@win2.maxx - 3) do |i|
        @win2.setpos(@win2.maxy / 2, i)
        @win2 << "*"
        @win2.refresh
        sleep 0.015
      end
    rescue
      Curses.close_screen
    end
    update_test
    sleep(2)
    begin # draw input
      draw_empty_window(@win3)
      @win3.setpos(@win3.maxy / 2, 1)
      @win3.addstr("Input: ")
      curs_set(1)
      @win3.refresh
      echo
      @input = @win3.getstr
      noecho
      curs_set(0)
      sleep(0.1)
    end
    begin # draw output window
      draw_empty_window(@win4)
      @win4.setpos(@win4.maxy / 2, 1)
      @win4.addstr("You have input: #{@input}")
      @win4.refresh
      sleep(2)
    end
  rescue
    Curses.close_screen
  end

  #############################################################################################################################

  def update_test
    # update first window with options
    @win1.setpos(3, 1)
    @win1.addstr("[ OPTIONS ]".center(@win1.maxx - 2, '-'))
    @win1.refresh
    sleep(0.5)
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
      when 'w' then position -= 1
      when 's' then position += 1
      when 'd' then break
      when 'q' then exit
      end
      position = @stations.length - 1 if position < 0
      position = 0 if position >= @stations.length
      draw_menu_window(window, position)
    end
    position
  end

  #############################################################################################################################

  # pure window stuff that can maybe be a module?

  def draw_empty_window(window)
    window.clear
    window.box("|", "-")
    window.setpos(1, 1)
    window.refresh
  end
end

app = App.new
app.run
