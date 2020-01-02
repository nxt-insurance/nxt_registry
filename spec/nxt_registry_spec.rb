RSpec.describe NxtRegistry do
  context 'shallow registry' do
    subject do
      extend NxtRegistry

      registry :developers do
        call(false)
      end
    end

    context 'when the key was not registered before' do
      it do
        subject.register(:callback, ->(arg) { "#{arg} Demirci" })
        expect(subject.resolve(:callback).call('Lütfi')).to eq('Lütfi Demirci')
      end
    end

    context 'when the key was already registered before' do
      it do
        subject.register(:callback, ->(arg) { "#{arg} Demirci" })

        expect {
          subject.register(:callback, ->(arg) { "#{arg} Demirci" })
        }.to raise_error KeyError, "Key 'callback' already registered in registry 'developers'"
      end
    end
  end

  context 'nested registry' do
    context 'when called by its name' do
      subject do
        extend NxtRegistry

        registry :from do
          nested :to do
            nested :kind, default: -> { [] }
          end
        end
      end

      it 'returns self' do
        expect(subject.from).to eq(subject)
      end
    end

    context 'when registering nested values' do
      subject do
        extend NxtRegistry

        registry :from do
          nested :to do
            nested :kind, default: -> { [] }
          end
        end
      end

      it do
        subject.from(:pending).to(:processing).kind(:after, -> { 'after transition callback' })
        expect(subject.from(:pending).to(:processing).kind(:after)).to eq('after transition callback')
      end
    end

    context 'when nested multiple times' do
      subject do
        Class.new do
          extend NxtRegistry

          registry :from do
            nested :to
            nested :other
          end
        end
      end

      it do
        expect { subject }.to raise_error ArgumentError, 'Multiple nestings on the same level'
      end
    end

    context 'attrs defined without default' do
      subject do
        extend NxtRegistry

        registry :from do
          nested :to do
            attr :b
          end
        end
      end

      context 'when registering a key that was defined' do
        it do
          expect(subject.from(:a).to(:b, 'b')).to eq('b')
          expect(subject.from(:a).to(:b)).to eq('b')
          expect { subject.from(:a).to(:b, 'b') }.to raise_error KeyError,  "Key 'b' already registered in registry 'from.to'"
        end
      end

      context 'when resolving a missing key' do
        it do
          expect { subject.from(:a).to(:b) }.to raise_error KeyError, "Key 'b' not registered in registry 'from.to'"
        end
      end

      context 'when registering a key that was not defined' do
        it do
          expect { subject.from(:a).to(:c, 'c') }.to raise_error KeyError, 'Keys are restricted to ["b"]'
        end
      end
    end

    context 'with the same attr defined multiple times' do
      subject do
        extend NxtRegistry

        registry :from do
          nested :to do
            attr :b
            attr :b
          end
        end
      end

      it do
        expect { subject }.to raise_error KeyError, "Attribute b already registered in from.to"
      end
    end
  end

  context 'recursive registry' do
    subject do
      extend NxtRegistry

      recursive_registry :level_0 do
        attr :andy
      end
    end

    it 'recursively creates registries as default values' do
      expect(subject.level_0(:a).level_1(:b).level_2(:c)).to be_a(NxtRegistry::RecursiveRegistry)
    end
  end

  context 'example from README' do
    subject do
      klass = Class.new do
        include NxtRegistry

        def passengers
          @passengers ||= begin
            registry :from do
              nested :to do
                nested :via do
                  attrs :train, :car, :plane, :horse
                  self.default = -> { [] }
                  self.memoize = true
                  call true
                  resolver ->(value) { value }
                end
              end
            end
          end
        end
      end

      klass.new
    end

    it do
      subject.passengers.from(:a).to(:b).via(:train) << 'Andy'
      subject.passengers.from(:a).to(:b).via(:car) << 'Lütfi'
      subject.passengers.from(:a).to(:b).via(:plane) << 'Nils'
      subject.passengers.from(:a).to(:b).via(:plane) << 'Rapha'

      expect(subject.passengers.from(:a).to(:b).via(:train)).to eq(%w[Andy])
      # Hash syntax with String keys since we transform keys to string per default
      expect(subject.passengers['a']['b']['train']).to eq(%w[Andy])

      expect(subject.passengers.from(:a).to(:b).via(:car)).to eq(%w[Lütfi])
      expect(subject.passengers.from(:a).to(:b).via(:plane)).to eq(%w[Nils Rapha])
    end
  end

  context 'resolver' do
    subject do
      klass = Class.new do
        include NxtRegistry

        def passengers
          @passengers ||= begin
            registry :from do
              nested :to do
                nested :via do
                  resolver ->(value) { "The passenger travels via: #{value}" }
                end
              end
            end
          end
        end
      end

      klass.new
    end

    it 'calls the resolver with the registered value' do
      subject.passengers.from(:a).to(:b).via(:train, 'ICE')
      expect(subject.passengers.from(:a).to(:b).via(:train)).to eq('The passenger travels via: ICE')
    end
  end

  describe '#configure' do
    subject do
      NxtRegistry::Registry.new(:from)
    end

    it do
      subject.configure do
        nested :to do
          nested :via do
            resolver ->(value) { "The passenger travels via: #{value}" }
          end
        end
      end

      subject.from(:a).to(:b).via(:train, 'ICE')
      expect(subject.from(:a).to(:b).via(:train)).to eq('The passenger travels via: ICE')
    end
  end

  describe '#on_key_already_registered' do
    subject do
      NxtRegistry::Registry.new(:test) do
        on_key_already_registered ->(key) { raise KeyError, "Key #{key} was no good" }
      end
    end

    it do
      subject.register(:andy, 'superman')
      expect { subject.register(:andy, 'superman') }.to raise_error KeyError, "Key andy was no good"
    end
  end

  describe '#on_key_not_registered' do
    subject do
      NxtRegistry::Registry.new(:test) do
        on_key_not_registered ->(key) { raise KeyError, "Key #{key} was never registered" }
      end
    end

    it do
      expect { subject.resolve(:andy) }.to raise_error KeyError, "Key andy was never registered"
    end
  end
end
