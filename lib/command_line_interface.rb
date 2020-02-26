require 'csv'
require_relative 'station.rb'
require_relative 'oyster_card.rb'

class Interface
  def initialize
    @stations = CSV.parse(File.read("./data/stations.csv")).drop(1).map! { |s| Station.new(s.first, s.last) }
  end

  def run
    print_string_at_speed("Welcome to your shiny new transport app!", 0.5)
    # print_string_at_speed("Here are some options:", 0.5)
    take_train(@stations.first, @stations.last, 0.5)
    # loop do
    #  options
    #  print "Input: "
    #  case gets.chomp
    #  when "1"
    #  when "2"
    #  when "3"
    #    start = gets.chomp
    #    finish = gets.chomp
    #    start_staion = nil
    #    finish_staion = nil
    #    @stations.each do |s|
    #      s.name.upcase == start
    #    end
    #    start_station = @sta
    #    take_train()
    #  end
    # end
    # take_train(@stations.first, @stations.last, 0.5)
  end

  def options
    print_string_at_speed("1. Top up oyster", 2)
    print_string_at_speed("2. Check balance", 2)
    print_string_at_speed("3. Take train", 2)
  end

  def stations
    puts "All Stations:"
    @stations.each { |s| puts "#{s.name} — Zone #{s.zone}" }
  end

  def take_train(start_station, end_station, speed)
    journey_length = 30
    character = '(˳˳_˳˳)'
    journey_length.times do |n|
      print "\r"
      print "[#{start_station.name}]#{'-' * n}#{character}#{'-' * (journey_length - n - 1)}[#{end_station.name}]"
      sleep(speed)
    end
    puts
    puts "Arrived at #{end_station.name}"
  end

  def print_string_at_speed(string, wait)
    string.length.times do |n|
      print "\r"
      print string.slice(0..n)
      sleep(wait / 10)
    end
    puts
  end
end

interface = Interface.new
interface.run
