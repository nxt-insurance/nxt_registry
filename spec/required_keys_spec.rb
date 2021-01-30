RSpec.describe NxtRegistry do
  let(:registry_1) do
    NxtRegistry::Registry.new do
      required_keys :a, :b, :c

      register(:a, 'A1')
      register(:b, 'B1')
      register(:c, 'C1')
    end
  end

  let(:registry_2) do
    NxtRegistry::Registry.new do
      required_keys :a, :b, :c

      register(:a, 'A2')
      register(:b, 'B2')
    end
  end

  context 'when all required keys are given' do
    it 'does not raise an error' do
      expect(registry_1.resolve(:a)).to eq('A1')
    end
  end

  context 'when required keys are missing' do
    it 'raises an error' do
      expect { registry_2 }.to raise_error NxtRegistry::Errors::RequiredKeyMissing, /Required key 'c' missing in Registry/
    end
  end
end
