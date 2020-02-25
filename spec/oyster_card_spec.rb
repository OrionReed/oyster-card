require 'oyster_card'

RSpec.describe(OysterCard) do
  let(:entry_double) { double("Station", name: "entry station") }
  let(:exit_double) { double("Station", name: "exit station") }

  it { is_expected.to(respond_to(:balance, :top_up, :touch_in, :touch_out, :in_journey?)) }
  it { is_expected.to(have_attributes(journeys: [])) }

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

    it 'changes status of in_journey? to true when in in_journey? is false' do
      subject.top_up(10)
      expect { subject.touch_in(entry_double) }.to(change { subject.in_journey? }.to(true))
    end

    it 'in_journey? stays true when already true' do
      subject.top_up(10)
      subject.touch_in(entry_double)
      expect { subject.touch_in(entry_double) }.to_not(change { subject.in_journey? })
    end

    it 'deducts minimum fare' do
      subject.top_up(10)
      subject.touch_in(entry_double)
      expect { subject.touch_out(exit_double) }.to(change { subject.balance }.by(-1))
    end
  end

  context '#touch_out' do
    it 'changes status of in_journey? to false when in in_journey? is true' do
      subject.top_up(10)
      subject.touch_in(entry_double)
      expect { subject.touch_out(exit_double) }.to(change { subject.in_journey? }.to(false))
    end
  end

  context 'entire journey' do
    it 'should not have exit station when touched in but not out' do
      subject.top_up(10)
      subject.touch_in(entry_double)
      expect(subject.journeys.last.value?(nil)).to(be(true))
    end
    it 'should deduct correct amount from balance' do
      subject.top_up(10)
      subject.touch_in(entry_double)
      expect { subject.touch_out(exit_double) }.to(change { subject.balance }.by(-1))
    end
    it 'should have no logged journeys at start' do
      expect(subject.journeys).to(be_empty)
    end
    it 'stores a single journey when touching in then out' do
      subject.top_up(10)
      subject.touch_in(entry_double)
      subject.touch_out(exit_double)
      expect(subject.journeys.length).to(eq(1))
    end
  end
end
