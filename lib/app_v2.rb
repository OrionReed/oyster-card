require 'csv'
require_relative 'station'
require_relative 'oyster_card'
require_relative 'clui_v2'
include(Curses)

class AppV2
  STATIONS = CSV.parse(File.read('./data/stations.csv')).drop(1).sort.map { |s| Station.new(s.first, s.last.to_i) }
  HEIGHT = 26
  WIDTH = 106
  TRAIN = '[ニニ]'
  SMOKE = ['o', '○', '◯', 'O', '•', '‘', '˚', '˙', '']
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
    @card = OysterCard.new
    @ui = CLUIV2.new(WIDTH, HEIGHT)
  end

  def run # main flow
    startup
    main_loop
  end

  def startup
    empty_main
    animate_lines(['• # •'], TEMPO / 8, cycle: true, update_each_segment: true)
    messaage = 'Welcome to the Underground'
    draw_message(' ' * (messaage.length + 3), :center, 1)
    draw_message(' ' * (messaage.length + 3), :center, 0)
    draw_message(' ' * (messaage.length + 3), :center, -1)
    draw_message('Welcome to the Underground')
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
    draw_message([["Account has ", A_NORMAL], ["£#{format_balance}", A_BOLD], [" and a max balance of ", A_NORMAL], ["£#{OysterCard::MAX_BALANCE}", A_BOLD]])
    wait_for_key("Press any key.")
  end

  def top_up
    value = 0
    1.times do
      empty_window_with_title('Please Enter Top-Up Amount')
      draw_message([["Account currently has ", A_NORMAL], ["£#{format_balance}", A_BOLD]])
      clear_input_window
      value = prompt_value("Enter Amount")
      next unless value.nil?
      draw_message([['Invalid Input, only use valid numbers', A_BLINK]])
      redo if choose_to?('try again')
      return
    end
    if @card.balance + value > OysterCard::MAX_BALANCE
      draw_title("Max balance reached")
      draw_message([["Adding ", A_NORMAL], ["£#{format('%.2f', (OysterCard::MAX_BALANCE - @card.balance))}", A_BOLD], [" from card.", A_NORMAL]], :center, -1)
      @card.top_up(OysterCard::MAX_BALANCE - @card.balance)
      draw_message([["Account now has max balance of ", A_NORMAL], ["£#{format_balance}", A_BOLD]])
      sleep(4)
      return
    end
    @card.top_up(value)
    hide_window(@input_window)
    empty_window_with_title('Balance')
    draw_message([["Account now has ", A_NORMAL], ["£#{format_balance}", A_BOLD]])
    sleep(2)
  end

  def history
    empty_window_with_title('Journey History')
    if @card.journey_log.history.empty?
      draw_message([["No history yet, why don't you ", A_NORMAL], ["take a train journey", A_BOLD]])
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
    counter = 0
    loop do # animate train
      @main.setpos((@main.maxy / 2) + 3, 0)
      @main.attrset(A_BOLD)
      @main.addstr("Travelled: #{pos.percent_of(WIDTH - TRAIN.length - 2).to_i}%".center(WIDTH))
      @main.attrset(A_NORMAL)
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
end

class Numeric
  def percent_of(n)
    to_f / n.to_f * 100.0
  end
end

app = App.new
app.run
