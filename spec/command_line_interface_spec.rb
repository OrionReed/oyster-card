require 'command_line_interface'

describe Interface do
  it { is_expected.to(respond_to(:run, :take_train)) }
end
