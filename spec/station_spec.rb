require 'station'

describe Station do
  subject { described_class.new("Baker Street", 1) }

  it 'has a name' do
    expect(subject.name).to(eq("Baker Street"))
  end

  it 'has a zone' do
    expect(subject.zone).to(eq(1))
  end
end
