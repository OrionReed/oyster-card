require 'journey'

describe Journey do
  let(:entry_station) { double(name: "Baker Street", zone: 1) }
  let(:exit_station) { double(name: "Wolf Street", zone: 2) }

  it 'has a default penalty fare' do
    expect(subject.fare).to(eq(Journey::MAX_FARE))
  end

  context 'when starting a journey' do
    subject { described_class.new(entry_station) }

    it 'has an entry station when given one' do
      expect(subject.entry_station).to(eq(entry_station))
    end

    it 'knows it is incomplete' do
      expect(subject).not_to(be_complete)
    end
  end

  context 'when ending a journey' do
    subject { described_class.new(entry_station) }

    it 'calculates the penalty fare' do
      subject.end(exit_station)
      expect(subject.fare).to(eq(2))
    end

    it 'returns itself' do
      expect(subject.end(exit_station)).to(eq(subject))
    end

    it 'knows it is complete' do
      subject.end(exit_station)
      expect(subject).to(be_complete)
    end
  end
end
