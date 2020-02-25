class OysterCard
  MAX_BALANCE = 90
  MIN_BALANCE = 1
  MIN_FARE = 1

  attr_reader :balance
  attr_reader :in_journey

  def initialize
    @balance = 0
    @in_journey = false
  end

  def top_up(amount)
    @balance += amount unless exceeds_max_balance(amount)
  end

  def touch_in
    exceeds_min_balance
    @in_journey = true if @balance >= MIN_BALANCE
  end

  def touch_out
    deduct(MIN_FARE)
    @in_journey = false
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
