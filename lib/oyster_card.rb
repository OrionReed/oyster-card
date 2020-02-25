class OysterCard
  MAX_BALANCE = 90
  MIN_BALANCE = 1
  MIN_FARE = 1

  attr_reader :balance
  attr_reader :journeys

  def initialize
    @balance = 0
    @journeys = []
  end

  def top_up(amount)
    @balance += amount unless exceeds_max_balance(amount)
  end

  def touch_in(entry_station)
    exceeds_min_balance
    @journeys << { entry_station => nil }
  end

  def touch_out(exit_station)
    deduct(MIN_FARE)
    @journeys.last.transform_values! { exit_station }
  end

  def in_journey?
    @journeys.any? && @journeys.last.value?(nil)
  end

  private

  def deduct(amount)
    @balance -= amount unless exceeds_min_balance
  end

  def exceeds_max_balance(amount)
    raise "Exceeded maximum balance" if @balance + amount > MAX_BALANCE
  end

  def exceeds_min_balance
    raise "Not enough money, please top up" if @balance < MIN_BALANCE
  end
end
