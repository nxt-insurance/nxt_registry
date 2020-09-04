module NxtRegistry
  class RecursiveRegistry < Registry
    def initialize(name, **options, &config)
      @level = options.fetch(:level) { 0 }

      @name = name
      @options = options
      @config = config

      super(name, **options, &config)
      set_nested_builder_as_default
    end

    attr_reader :name

    private

    attr_reader :options, :config, :level

    def set_nested_builder_as_default
      self.default = NestedRegistryBuilder.new do
        RecursiveRegistry.new("level_#{(level + 1)}", **options.merge(level: (level + 1)), &config)
      end
    end
  end
end
