require 'oyster_card'

RSpec.describe(OysterCard) do
  let(:dbl_station) { double("Station", name: "test station") }

  it { is_expected.to(respond_to(:balance, :top_up, :touch_in, :touch_out)) }
  it { is_expected.to(have_attributes(in_journey: false)) }

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
      expect { subject.touch_in(dbl_station) }.to(raise_error("Not enough money, please top up"))
    end

    it 'changes status of in_journey to true when in in_journey is false' do
      subject.top_up(10)
      expect { subject.touch_in(dbl_station) }.to(change { subject.in_journey }.to(true))
    end

    it 'in_journey stays true when already true' do
      subject.top_up(10)
      subject.touch_in(dbl_station)
      expect { subject.touch_in(dbl_station) }.to_not(change { subject.in_journey })
    end

    it 'deducts minimum fare' do
      subject.top_up(10)
      subject.touch_in(dbl_station)
      expect { subject.touch_out }.to(change { subject.balance }.by(-1))
    end

    it 'remembers station' do
      subject.top_up(10)
      subject.touch_in(dbl_station)
      expect(subject.entry_station).to(eq(dbl_station))
    end
  end

  context '#touch_out' do
    it 'changes status of in_journey to false when in in_journey is true' do
      subject.top_up(10)
      subject.touch_in(dbl_station)
      expect { subject.touch_out }.to(change { subject.in_journey }.to(false))
    end
    it 'in_journey stays false when already false' do
      subject.top_up(10)
      subject.touch_out
      expect { subject.touch_out }.to_not(change { subject.in_journey })
    end
  end
end
