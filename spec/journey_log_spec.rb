require 'journey_log'

describe JourneyLog do
  let(:entry_station) { double(name: "Baker Street", zone: 1) }
  let(:exit_station) { double(name: "Wolf Street", zone: 2) }

  context '#start' do
    it 'method exists' do
      expect(subject).to(respond_to(:start))
    end
    it 'begins current journey' do
      subject.start(entry_station)
      expect(subject.current).not_to(be_nil)
    end
  end
  context '#finish' do
    it 'method exists' do
      expect(subject).to(respond_to(:finish))
    end
    it 'adds 1 journey to log' do
      subject.start(entry_station)
      expect { subject.finish(exit_station) }.to(change { subject.history.length }.by(1))
    end
  end
  context '#history' do
    it 'method exists' do
      expect(subject).to(respond_to(:history))
    end
  end
end
