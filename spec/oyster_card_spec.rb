require 'oyster_card'

describe(OysterCard) do
  let(:entry_double) { double("Station", name: "entry station", zone: 1) }
  let(:exit_double) { double("Station", name: "exit station", zone: 2) }

  it { is_expected.to(respond_to(:balance, :top_up, :touch_in, :touch_out)) }

  it 'has default balance of 0' do
    expect(subject.balance).to(eq(0))
  end

  it 'adds to balance when topped up' do
    expect { subject.top_up(5) }.to(change { subject.balance }.by(5))
  end

  it 'throws an error when exceeding max balance' do
    expect { subject.top_up(OysterCard::MAX_BALANCE + 1) }.to(raise_error("Exceeded maximum balance"))
  end

  context '#touch_in' do
    it 'raises error when there are insufficient funds' do
      expect { subject.touch_in(entry_double) }.to(raise_error("Not enough money, please top up"))
    end

    it 'does not end journey if already in one' do
      subject.top_up(10)
      subject.touch_in(entry_double)
      expect { subject.touch_in(entry_double) }.to_not(change { subject.journey_log.current.complete? })
    end

    it 'deducts correct fare' do
      subject.top_up(10)
      subject.touch_in(entry_double)
      expect { subject.touch_out(exit_double) }.to(change { subject.balance }.by(-2))
    end
  end

  context '#touch_out' do
    it 'changes status of complete to true' do
      subject.top_up(10)
      subject.touch_in(entry_double)
      subject.touch_out(exit_double)
      expect(subject.journey_log.current.complete?).to(be(true))
    end
  end
end
