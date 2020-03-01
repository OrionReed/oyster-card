require_relative 'journey.rb'
require_relative 'journey_log.rb'

class OysterCard
  MAX_BALANCE = 90
  MIN_BALANCE = 1

  attr_reader :balance
  attr_reader :journey_log

  def initialize
    @balance = 0
    @journey_log = JourneyLog.new
  end

  def top_up(amount)
    @balance += amount unless exceeds_max_balance(amount)
  end

  def touch_in(entry_station)
    exceeds_min_balance
    @journey_log.start(entry_station)
  end

  def touch_out(exit_station)
    @journey_log.finish(exit_station)
    deduct(@journey_log.current.fare)
  end

  private

  def deduct(amount)
    @balance -= amount unless exceeds_min_balance
  end

  def exceeds_max_balance(amount)
    # raise "#{amount} to top up"
    raise "Exceeded maximum balance [#{amount}, #{MAX_BALANCE}]" if (@balance + amount).to_i > MAX_BALANCE
  end

  def exceeds_min_balance
    raise "Not enough money, please top up" if @balance < MIN_BALANCE
  end
end
