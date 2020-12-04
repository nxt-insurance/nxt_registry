RSpec.describe NxtRegistry::Singleton do
  describe '.include' do
    let(:singleton) do
      Class.new do
        include NxtRegistry::Singleton

        registry do
          register(:aki, 'ito')
        end
      end
    end

    it { expect(singleton.resolve!(:aki)).to eq('ito') }
  end

  describe '.extend' do
    let(:singleton) do
      Class.new do
        extend NxtRegistry::Singleton

        registry do
          register(:aki, 'ito')
        end
      end
    end

    it { expect(singleton.resolve!(:aki)).to eq('ito') }
  end
end
