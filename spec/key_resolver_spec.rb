RSpec.describe NxtRegistry do
  subject do
    NxtRegistry::Registry.new do
      key_resolver ->(key) { key * 2 }

      register(:aa, 'A')
      register(:bb, 'B')
      register(:cc, 'C')
    end
  end

  it 'applies the key resolver' do
    expect(subject.resolve(:a)).to eq('A')
  end

  context 'when nested' do
    subject do
      NxtRegistry::Registry.new do
        key_resolver ->(key) { key * 2 }

        register(:aa, inherit_options: true) do
          register(:bb, 'B')
        end
      end
    end

    it 'applies the key resolver' do
      expect(subject.resolve(:a, :b)).to eq('B')
    end
  end
end
