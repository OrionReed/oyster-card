class Journey
  MIN_FARE = 1
  MAX_FARE = 6
  attr_reader :entry_station
  attr_reader :exit_station

  def initialize(station = nil)
    @entry_station = station
    @exit_station = nil
  end

  def end(station)
    @exit_station = station
    self
  end

  def complete?
    p(entry_station)
    p(exit_station)
    !(entry_station.nil? || exit_station.nil?)
  end

  def fare
    return MAX_FARE if @entry_station.nil? || @exit_station.nil?
    (entry_station.zone - exit_station.zone).abs + MIN_FARE
  end
end
