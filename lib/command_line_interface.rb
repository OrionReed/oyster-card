require 'curses'
require 'csv'
require_relative 'station.rb'
require_relative 'oyster_card.rb'
require_relative 'dev/display.rb'

class Interface
  STATIONS_PATH = "./data/stations.csv"

  def initialize
    @stations = CSV.parse(File.read(STATIONS_PATH)).drop(1).map { |s| Station.new(s.first, s.last.to_i) }
    @card = OysterCard.new
  end

  def run
    Display.draw("Welcome to the London Underground.")
    sleep(0.5)
    loop do
      options
      Display.newline
      input
    end
  end

  def options
    gets.chomp
    Display.newline
    Display.draw("Here are your options:")
    Display.draw_list(
      ["1. Top up oyster",
       "2. Check balance",
       "3. Show map",
       "4. Take train",
       "5. Quit"]
    )
  end

  def input
    case Display.prompt("Input: ")
    when "1" then top_up
    when "2" then balance
    when "3" then stations
    when "4" then train_journey
    when "5" then exit
    end
  end

  def top_up
    Display.newline
    @card.top_up(Display.prompt("Top up amount: ").to_i)
    balance
  end

  def balance
    Display.newline
    Display.puts("Your balance is currently £#{@card.balance}")
  end

  def stations
    Display.newline
    Display.draw("All Stations:")
    @stations.each { |s| Display.draw("#{s.name} — Zone #{s.zone}") }
  end

  def train_journey
    a = search_stations(Display.prompt("Start at: "))
    if a.is_a?(String)
      Display.puts("No station with name '#{a}' found.")
      return
    end
    b = search_stations(Display.prompt("End at: "))
    if b.is_a?(String)
      Display.puts("No station with name '#{b}' found.")
      return
    end
    Display.animate_train(a.name, b.name, 20)
    Display.newline
    Display.draw("Arrived at #{b.name}")
  end

  def search_stations(input)
    @stations.each do |s|
      return s if s.name.downcase.start_with?(input.downcase)
    end
    input
  end
end

Interface.new.run
