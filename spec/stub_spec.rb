# frozen_string_literal: true

RSpec.describe NxtRegistry do # rubocop:disable Metrics/BlockLength
  let(:first_klass) do
    Class.new do
      extend NxtRegistry

      registry(:w) do
        register(:a) do
          register(:b, 'b')
          register(/\A\d{2}\z/, 'c')
        end
      end
    end
  end
  let(:first_instance) { first_klass.new }
  let(:first_registry) { first_klass.registry(:w) }

  let(:second_klass) do
    Class.new do
      include NxtRegistry::Singleton

      registry do
        register(:a) do
          register(:b, 'b')
          register(/\A\d{2}\z/, 'c')
        end
      end
    end
  end
  let(:second_instance) { second_klass.new }
  let(:second_registry) { second_instance.class }

  let(:third_klass) do
    Class.new do
      extend NxtRegistry

      registry(:w, default: 'default_value') do
        register(:a, inherit_options: true) do
          register(:b, 'b')
          register(/\A\d{2}\z/, 'c')
        end
      end
    end
  end
  let(:third_instance) { third_klass.new }
  let(:third_registry) { third_klass.registry(:w) }

  let(:fourth_klass) do
    Class.new do
      extend NxtRegistry

      registry :w do
        level :to do
          level :via
        end
      end
    end
  end
  let(:fourth_instance) { fourth_klass.new }
  let(:fourth_registry) { fourth_klass.registry(:w) }

  shared_examples_for 'stubbable' do
    it 'stubs the key' do
      registry.enable_stubs!

      registry.stub(:a, :b, value: 'c')

      expect(registry.resolve(:a, :b)).to eq('c')
    end

    it 'stubs the pattern key' do
      registry.enable_stubs!

      registry.stub(:a, 99, value: 'd')

      expect(registry.resolve(:a, 99)).to eq('d')
      expect(registry.resolve(:a, 33)).to eq('c')
    end

    it 'returns the original value once unstubbed' do
      registry.enable_stubs!

      registry.stub(:a, :b, value: 'c')
      expect(registry.resolve(:a, :b)).to eq('c')

      registry.unstub
      expect(registry.resolve(:a, :b)).to eq('b')
    end

    it 'repeated enable_stubs! calls do not enter a cycle' do
      registry.enable_stubs!
      value = registry.enable_stubs!

      expect(value).to eq(nil)
    end
  end

  context 'with an extended registry' do
    let(:klass) { first_klass }
    let(:instance) { first_instance }
    let(:registry) { first_registry }

    it_behaves_like 'stubbable'

    it 'raises if a stubbed key was not present' do
      registry.enable_stubs!

      expect { registry.stub(:a, :d, value: 'd') }.to raise_error(ArgumentError)
    end
  end

  context 'with a singleton registry' do
    let(:klass) { second_klass }
    let(:instance) { second_instance }
    let(:registry) { second_registry }

    it_behaves_like 'stubbable'

    it 'raises if a stubbed key was not present' do
      registry.enable_stubs!

      expect { registry.stub(:a, :d, value: 'd') }.to raise_error(ArgumentError)
    end
  end

  context 'with an extended registry and a default option' do
    let(:klass) { third_klass }
    let(:instance) { third_instance }
    let(:registry) { third_registry }

    it_behaves_like 'stubbable'

    it 'does not raise if a stubbed key was not present' do
      registry.enable_stubs!

      expect { registry.stub(:a, :d, value: 'd') }.to_not raise_error(ArgumentError)

      expect(registry.resolve(:a, :d)).to eq('d')
    end
  end

  context 'with an extended registry and a level' do # rubocop:disable Metrics/BlockLength
    let(:klass) { fourth_klass }
    let(:instance) { fourth_instance }
    let(:registry) { fourth_registry }

    it 'stubs the key' do
      registry.enable_stubs!

      registry.stub(:a, :b, value: 'c')

      expect(registry.resolve(:a, :b)).to eq('c')
    end

    it 'stubs the pattern key' do
      registry.enable_stubs!

      registry.stub(:a, 99, value: 'd')

      expect(registry.resolve(:a, 99)).to eq('d')
      expect(registry.resolve(:a, 33)).to be_an_instance_of(::NxtRegistry::Registry)
    end

    it 'returns the original value once unstubbed' do
      registry.enable_stubs!

      registry.stub(:a, :b, value: 'c')
      expect(registry.resolve(:a, :b)).to eq('c')

      registry.unstub
      expect(registry.resolve(:a, :b)).to be_an_instance_of(::NxtRegistry::Registry)
    end

    it 'repeated enable_stubs! calls do not enter a cycle' do
      registry.enable_stubs!
      value = registry.enable_stubs!

      expect(value).to eq(nil)
    end

    it 'returns the original value from the bottom level once unstubbed' do
      registry.resolve(:a, :b).register(:q, 'q')
      registry.enable_stubs!

      registry.stub(:a, :b, :q, value: 'o')
      expect(registry.resolve(:a, :b, :q)).to eq('o')

      registry.unstub
      expect(registry.resolve(:a, :b, :q)).to eq('q')
    end

    it 'does not raise if a stubbed key was not present' do
      registry.enable_stubs!
      registry.stub(:a, :d, value: 'w')

      expect(registry.resolve(:a, :d)).to eq('w')
    end
  end

  it 'different registries do not share stubs' do
    first_registry.enable_stubs!
    second_registry.enable_stubs!

    first_registry.stub(:a, :b, value: 'c')

    expect(first_registry.resolve(:a, :b)).to eq('c')
    expect(second_registry.resolve(:a, :b)).to eq('b')
  end

  it 'instances of the same class with a shared registry share stubs' do
    first = first_klass.new
    second = first_klass.new

    first_klass.registry(:w).enable_stubs!
    first_klass.registry(:w).stub(:a, :b, value: 'c')

    expect(first.class.registry(:w).resolve(:a, :b)).to eq('c')
    expect(second.class.registry(:w).resolve(:a, :b)).to eq('c')
  end
end
