def evolve(rule, state)
  def state.[](x)
    (x < 0) || (x >= length) ? 0 : fetch(x)
  end
  next_state = []
  (-1...state.length + 1).each do |i|
    bit = state[i + 1] | (state[i] << 1) | (state[i - 1] << 2)
    mask = 1 << bit
    next_state[i + 1] = (mask & rule) != 0 ? 1 : 0
  end
  next_state
end

rule = ARGV[0].to_i
state = [1]
max = 100
max.times do |gen|
  (max - gen).times { print ' ' }
  state.each { |x| print x == 1 ? '*' : ' ' }
  puts
  state = evolve(rule, state)
  sleep 0.01
end
