RSpec.describe NxtRegistry do
  context 'shallow registry' do
    subject do
      extend NxtRegistry
      registry :developers
    end

    context 'when the key was not registered before' do
      it do
        subject.register(:callback, ->(arg) { "#{arg} done" })
        expect(subject.resolve(:callback)).to eq('callback done')
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

    describe '#fetch' do
      context 'when the key is missing' do
        context 'and no default is given' do
          it 'raises an error' do
            expect { subject.fetch(:missing) }.to raise_error KeyError
          end
        end

        context 'and a default is given' do
          context 'default value' do
            it 'returns the default' do
              expect(subject.fetch(:missing, 'not missing')).to eq('not missing')
            end
          end

          context 'default block' do
            it 'returns the default' do
              expect(subject.fetch(:missing) { 'not missing' }).to eq('not missing')
            end
          end
        end
      end
    end
  end

  context 'with patterns' do
    subject do
      extend NxtRegistry

      registry :developers do
        call(false)
      end
    end

    context 'when the key was not registered before' do
      it do
        subject.register(/\d+/, 'This must be a number')
        subject.register(/\w+/, 'This must be a string')

        expect(subject.resolve('123')).to eq('This must be a number')
        expect(subject.resolve('Lütfi')).to eq('This must be a string')
      end
    end

    context 'when the key was already registered before' do
      it do
        subject.register(/\d+/, 'This must be a number')

        expect {
          subject.register(/\d+/, 'This must be a number')
        }.to raise_error KeyError, "Key '(?-mix:\\d+)' already registered in registry 'developers'"
      end
    end

    describe '#fetch' do
      context 'when the key is missing' do
        context 'and no default is given' do
          it 'raises an error' do
            expect { subject.fetch(:missing) }.to raise_error KeyError
          end
        end

        context 'and a default is given' do
          context 'default value' do
            it 'returns the default' do
              expect(subject.fetch(:missing, 'not missing')).to eq('not missing')
            end
          end

          context 'default block' do
            it 'returns the default' do
              expect(subject.fetch(:missing) { 'not missing' }).to eq('not missing')
            end
          end
        end
      end
    end
  end

  context 'with patterns' do
    subject do
      extend NxtRegistry

      registry :developers do
        call(false)
      end
    end

    context 'when the key was not registered before' do
      it do
        subject.register(/\d+/, 'This must be a number')
        subject.register(/\w+/, 'This must be a string')

        expect(subject.resolve('123')).to eq('This must be a number')
        expect(subject.resolve('Lütfi')).to eq('This must be a string')
      end
    end

    context 'when the key was already registered before' do
      it do
        subject.register(/\d+/, 'This must be a number')

        expect {
          subject.register(/\d+/, 'This must be a number')
        }.to raise_error KeyError, "Key '(?-mix:\\d+)' already registered in registry 'developers'"
      end
    end

    describe '#fetch' do
      context 'when the key is missing' do
        context 'and no default is given' do
          it 'raises an error' do
            expect { subject.fetch(:missing) }.to raise_error KeyError
          end
        end

        context 'and a default is given' do
          context 'default value' do
            it 'returns the default' do
              expect(subject.fetch(:missing, 'not missing')).to eq('not missing')
            end
          end

          context 'default block' do
            it 'returns the default' do
              expect(subject.fetch(:missing) { 'not missing' }).to eq('not missing')
            end
          end
        end
      end
    end
  end

  context 'registering nested registries' do
    subject do
      extend NxtRegistry

      registry :developers do
        register(:frontend) do
          register(:igor, 'Igor')
          register(:ben, 'Ben')
        end

        register(:backend, default: -> { 'Rubyist' }) do
          register(:rapha, 'Rapha')
          register(:aki, 'Aki')
        end
      end
    end

    it do
      expect(subject.resolve(:frontend).resolve(:igor)).to eq('Igor')
      expect(subject.resolve(:backend).resolve(:rapha)).to eq('Rapha')
      expect(subject.developers(:frontend).frontend(:igor)).to eq('Igor')

      expect(subject.resolve!(:backend, :other)).to eq('Rubyist')
      expect { subject.resolve!(:fronted, :other) }.to raise_error(KeyError)
    end
  end

  context 'inheriting options in nested registries' do
    subject do
      extend NxtRegistry

      registry :developers, default: 'options can be inherited' do
        register(:frontend, inherit_options: true) do
          register(:igor, 'Igor')
          register(:ben, 'Ben')
        end

        register(:backend, default: -> { 'Rubyist' }) do
          register(:rapha, 'Rapha')
          register(:aki, 'Aki')
        end
      end
    end

    it do
      expect(subject.resolve(:frontend).resolve(:no_registered)).to eq('options can be inherited')
      expect(subject.resolve(:backend).resolve(:no_registered)).to eq('Rubyist')
    end
  end

  context 'nesting with patterns' do
    subject do
      extend NxtRegistry

      registry :status_codes do
        register(/4\d{2}/) do
          register(400, 'Bad Request')
          register(404, 'Not Found')
        end

        register(/5\d{2}/) do
          register(500, 'Internal Server Error')
          register(503, 'Service Unavailable')
        end
      end
    end

    it do
      expect(subject.resolve(400).resolve(404)).to eq('Not Found')
      expect(subject.resolve(500).resolve(503)).to eq('Service Unavailable')
    end
  end

  context 'nested registry' do
    context 'when called by its name' do
      subject do
        extend NxtRegistry

        registry :from do
          level :to do
            level :kind, default: -> { [] }
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
          level :to do
            register(:injected, 'ha ha ha')
            level :kind, default: -> { [] }
          end
        end
      end

      it do
        subject.from(:pending).to(:processing).kind(:after, -> { 'after transition callback' })
        expect(subject.from(:pending).to(:processing).kind(:after)).to eq('after transition callback')
        expect(subject.resolve(:pending, :processing, :after)).to eq('after transition callback')

        expect(subject.from(:pending).to(:injected)).to eq('ha ha ha')
      end
    end

    context 'when nested multiple times' do
      subject do
        Class.new do
          extend NxtRegistry

          registry :from do
            level :to
            level :other
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
          level :to do
            level :via, allowed_keys: %i[c d]
          end
        end
      end

      context 'when registering a key that was already registered' do
        it do
          expect(subject.from(:a).to(:b).via(:c, 'c')).to eq('c')
          expect(subject.from(:a).to(:b).via(:c)).to eq('c')
          expect(subject.resolve(:a, :b, :c)).to eq('c')

          expect { subject.from(:a).to(:b).via(:c, 'c') }.to raise_error KeyError,  "Key 'c' already registered in registry 'from.to.via'"
        end
      end

      context 'when resolving a missing key' do
        it do
          expect { subject.from(:a).to(:b).via!(:c) }.to raise_error KeyError, "Key 'c' not registered in registry 'from.to.via'"
        end
      end

      context 'when registering a key that was not defined' do
        it do
          expect { subject.from(:a).to(:b).via(:f, 'f') }.to raise_error KeyError, 'Keys are restricted to ["c", "d"]'
        end
      end
    end
  end

  context 'with attr called multiple times' do
    subject do
      extend NxtRegistry

      registry :from do
        level :to do
          attr :b
          attr :c
        end
      end
    end

    it 'allows any of the attributes to be registered' do
      expect(subject.from(:a).to(:b, 'b')).to eq('b')
      expect(subject.from(:a).to(:c, 'c')).to eq('c')
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
              level :to do
                level :via do
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

    before do
      subject.passengers.from(:a).to(:b).via(:train, ['Andy']) << 'Andy'
      subject.passengers.from(:a).to(:b).via(:car) << 'Lütfi'
      subject.passengers.from(:a).to(:b).via(:plane) << 'Nils'
      subject.passengers.from(:a).to(:b).via(:plane) << 'Rapha'
    end

    it do
      expect(subject.passengers.from(:a).to(:b).via(:train)).to eq(%w[Andy Andy])
      # Hash syntax with String keys since we transform keys to string per default
      expect(subject.passengers['a']['b']['train']).to eq(%w[Andy Andy])

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
              level :to do
                level :via do
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
        level :to do
          level :via do
            resolver ->(value) { "The passenger travels via: #{value}" }
          end
        end
      end

      subject.from(:a).to(:b).via(:train, 'ICE')
      expect(subject.from(:a).to(:b).via(:train)).to eq('The passenger travels via: ICE')
    end
  end

  describe 'accessor option' do
    context 'with levels' do
      subject do
        NxtRegistry::Registry.new(:path, accessor: :from) do
          level :to do
            level :via do
              resolver ->(value) { "The passenger travels via: #{value}" }
            end
          end
        end
      end

      it 'defines custom accessors' do
        subject.from(:a).to(:b).via(:train, 'ICE')
        expect(subject.from(:a).to(:b).via(:train)).to eq('The passenger travels via: ICE')
      end
    end

    context 'when nested' do
      subject do
        extend NxtRegistry

        registry :developers do
          register(:frontend, accessor: :dev) do
            register(:igor, 'Igor')
            register(:ben, 'Ben')
          end

          register(:backend, default: -> { 'Rubyist' }, accessor: :dev) do
            register(:rapha, 'Rapha')
            register(:aki, 'Aki')
          end
        end
      end

      it 'defines custom accessors' do
        expect(subject.developers(:frontend).dev(:igor)).to eq('Igor')
        expect(subject.developers(:backend).dev(:rapha)).to eq('Rapha')
      end
    end

    context 'when flat' do
      let(:test_class) do
        Class.new do
          include NxtRegistry

          def devs
            registry :developers, accessor: :dev do
              register(:anthony, 'Anthony')
              register(:scotty, 'Scotty')
              register(:nils, 'Nils')
            end
          end
        end
      end

      subject { test_class.new }

      it 'defines custom accessors' do
        expect(subject.devs.dev(:anthony)).to eq('Anthony')
        expect(subject.devs.dev(:scotty)).to eq('Scotty')
        expect(subject.devs.dev(:nils)).to eq('Nils')
      end
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
      expect { subject.resolve!(:andy) }.to raise_error KeyError, "Key andy was never registered"
    end
  end

  context 'defaults' do
    context 'when the default value is a block' do
      context 'that takes an argument' do
        subject do
          extend NxtRegistry

          registry :developers, default: ->(original) { original } do
            register(:ruby, 'Gem')
          end
        end

        it 'calls the block with the key as argument' do
          expect(subject.resolve(:javascript)).to eq('javascript')
        end
      end

      context 'that takes no arguments' do
        subject do
          extend NxtRegistry

          registry :developers, default: -> { 'undefined' } do
            register(:ruby, 'Gem')
          end
        end

        it 'calls the block' do
          expect(subject.resolve(:javascript)).to eq('undefined')
        end
      end
    end
  end

  context 'readers' do
    context 'class level' do
      subject do
        Class.new do
          extend NxtRegistry

          REGISTRY = registry :developers do
            call(false)
          end
        end
      end

      it do
        expect(subject.registry(:developers)).to eq(subject.const_get('REGISTRY'))
      end
    end

    context 'instance level' do
      let(:test_class) do
        Class.new do
          include NxtRegistry

          def devs
            registry :developers do
              call(false)
            end
          end
        end
      end

      subject { test_class.new }

      it do
        expect(subject.devs).to eq(subject.registry(:developers))
      end
    end
  end

  describe '#clone' do
    subject do
      extend NxtRegistry

      registry :developers do
        call(false)
      end
    end

    let(:clone) { subject.clone }

    it 'clones the store' do
      expect { clone.register(:luetfi, 'legend') }.to_not change { subject.developers.to_h }
      expect { subject.register(:rapha, 'dog') }.to_not change { clone.developers.to_h }
    end

    it 'clones patterns' do
      expect { clone.register(/\d+/, '123') }.to_not change { subject.send(:patterns) }
      expect { subject.register(/\w+/, 'dog') }.to_not change { clone.send(:patterns) }
    end

    it 'clones required keys' do
      expect { clone.required_keys(:andy) }.to_not change { subject.send(:required_keys) }
      expect { subject.required_keys(:nils) }.to_not change { clone.send(:required_keys) }
    end

    it 'clones allowed keys' do
      expect { clone.allowed_keys(:rapha) }.to_not change { subject.send(:allowed_keys) }
      expect { subject.allowed_keys(:lütfi) }.to_not change { clone.send(:allowed_keys) }
    end
  end
end
