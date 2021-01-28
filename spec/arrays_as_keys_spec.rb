RSpec.describe NxtRegistry do
  let(:subject) do
    NxtRegistry::Registry.new do
      register([:a, :b, :c], 'ABC')
    end
  end

  it 'registers the value for all keys' do
    %i[a b c].each do |char|
      expect(subject.resolve(char)).to eq('ABC')
    end
  end
end
