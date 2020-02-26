require_relative 'journey.rb'
class JourneyLog
  attr_reader :current

  def initialize
    @journeys = []
    @current = Journey.new
  end

  def start(station)
    @current = Journey.new(station)
  end

  def finish(station)
    @current.end(station) unless @current.complete?
    @journeys << @current
  end

  def history
    @journeys
  end
end
