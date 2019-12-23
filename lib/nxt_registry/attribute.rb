module NxtRegistry
  class Attribute
    def initialize(name, registry, **options)
      @name = name
      @registry = registry
      @namespace = [name, registry.send(:namespace)].join('.')
    end

    def eql?(other)
      { name => registry.object_id } == { other.send(:name) => other.send(:registry).object_id }
    end

    private

    attr_reader :name, :registry
  end
end
