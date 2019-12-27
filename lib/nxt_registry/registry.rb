module NxtRegistry
  class Registry
    def initialize(name, **options, &config)
      @name = name
      @parent = options[:parent]
      @namespace = [parent, self].compact.map(&:name).join('.')
      @default = options.fetch(:default) { Blank.new }
      @memoize = options.fetch(:memoize) { true }
      @call = options.fetch(:call) { true }
      @resolver = options.fetch(:resolver) { ->(value) { value } }
      # on_key_already_registered = options.fetch(:on_key_already_registered) { ->(key, value) { } }
      # on_key_not_registered = options.fetch(:on_key_not_registered) { ->(key) { key} }
      @config = config
      @store = { }
      @attrs = nil
      @is_leaf = true

      configure(&config)
    end

    attr_reader :name

    def nested(name, **options, &config)
      options = options.merge(parent: self)

      if default.is_a?(Blank)
        self.is_leaf = false

        self.default = NestedRegistryBuilder.new do
          Registry.new(name, **options, &config)
        end

        default.call
      elsif default.is_a?(NestedRegistryBuilder)
        raise ArgumentError, "Multiple nestings on the same level"
      else
        raise ArgumentError, "Default values cannot be defined on registries that nest others"
      end
    end

    def attr(name)
      raise KeyError, "Attribute #{name} already registered in #{namespace}" if attrs.has_key?(name)

      attrs[name] = Attribute.new(name, self)
    end

    def attrs(*args)
      @attrs ||= {}
      return @attrs unless args.any?

      args.each { |name| attr(name) }
    end

    def register(key, value)
      __register(key, value)
    end

    def register!(key, value)
      __register(key, value, raise: true)
    end

    def resolve(key)
      __resolve(key)
    end

    def resolve!(key)
      __resolve(key, raise: true)
    end

    def to_h
      store
    end

    delegate_missing_to :store

    def configure(&block)
      define_accessors
      define_interface

      if block.present?
        if block.arity == 1
          instance_exec(self, &block)
        else
          instance_exec(&block)
        end
      end
    end

    private

    attr_reader :namespace, :parent, :config, :store
    attr_accessor :is_leaf

    def is_leaf?
      @is_leaf
    end

    def __register(key, value, raise: true)
      raise ArgumentError, "Not allowed to register values in a registry that contains nested registries" unless is_leaf
      raise KeyError, "Keys are restricted to #{attrs.keys}" if attribute_not_allowed?(key)
      raise NxtRegistry::Errors::DuplicateKeyError, "Key '#{key}' already registered in registry '#{namespace}'" if store.has_key?(key) && raise

      store[key] = value
    end

    def __resolve(key, raise: true)
      value = if is_leaf?
        if store.has_key?(key)
          store.fetch(key)
        else
          if default.is_a?(Blank)
            if raise
              raise NxtRegistry::Errors::MissingKeyError, "Key '#{key}' not registered in registry '#{namespace}'"
            else
              nil
            end
          else
            value = resolve_default
            return value unless memoize

            store[key] ||= value
          end
        end
      else
        # Call nested registry builder when we are not a leaf
        store[key] ||= default.call
      end

      resolver.call(value)
    end

    def define_interface
      define_singleton_method name do |key = Blank.new, value = Blank.new|
        return self if key.is_a?(Blank)

        if value.is_a?(Blank)
          resolve(key)
        else
          register(key, value)
        end
      end

      define_singleton_method "#{name}!" do |key = Blank.new, value = Blank.new|
        return self if key.is_a?(Blank)

        if value.is_a?(Blank)
          resolve!(key)
        else
          register!(key, value)
        end
      end
    end

    def define_accessors
      %w[default memoize call resolver].each do |attribute|
        define_singleton_method attribute do |value = Blank.new|
          if value.is_a?(Blank)
            instance_variable_get("@#{attribute}")
          else
            instance_variable_set("@#{attribute}", value)
          end
        end

        define_singleton_method "#{attribute}=" do |value|
          instance_variable_set("@#{attribute}", value)
        end
      end
    end

    def attribute_not_allowed?(key)
      return if attrs.empty?

      attrs.keys.exclude?(key)
    end

    def resolve_default
      if call && default.respond_to?(:call)
        default.call
      else
        default
      end
    end
  end
end
