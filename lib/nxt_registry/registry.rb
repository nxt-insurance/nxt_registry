module NxtRegistry
  class Registry
    def initialize(name, **options, &config)
      @name = name
      @parent = options[:parent]
      @is_leaf = true
      @namespace = [parent, self].compact.map(&:name).join('.')
      @config = config
      @store = {}
      @attrs = nil

      setup_defaults(options)
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
      key = transformed_key(name)
      raise KeyError, "Attribute #{key} already registered in #{namespace}" if attrs[key]

      attrs[key] = Attribute.new(key, self)
    end

    def attrs(*args)
      @attrs ||= {}
      return @attrs unless args.any?

      args.each { |name| attr(name) }
    end

    def register(key, value)
      __register(key, value, raise: true)
    end

    def register!(key, value)
      __register(key, value, raise: false)
    end

    def resolve(key)
      __resolve(key, raise: true)
    end

    def resolve!(key)
      __resolve(key, raise: false)
    end

    def to_h
      store
    end

    def [](key)
      store[transformed_key(key)]
    end

    def []=(key, value)
      store[transformed_key(key)] = value
    end

    def keys
      store.keys.map(&method(:transformed_key))
    end

    def key?(key)
      store.key?(transformed_key(key))
    end

    def include?(key)
      store.include?(transformed_key(key))
    end

    def exclude?(key)
      store.exclude?(transformed_key(key))
    end

    def fetch(key, **opts, &block)
      store.fetch(transformed_key(key), **opts, &block)
    end

    delegate :size, :values, :each, to: :store

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
      key = transformed_key(key)

      raise ArgumentError, "Not allowed to register values in a registry that contains nested registries" unless is_leaf
      raise KeyError, "Keys are restricted to #{attrs.keys}" if attribute_not_allowed?(key)

      on_key_already_registered && on_key_already_registered.call(key) if store[key] && raise

      store[key] = value
    end

    def __resolve(key, raise: true)
      key = transformed_key(key)

      value = if is_leaf?
        if store[key]
          store.fetch(key)
        else
          if default.is_a?(Blank)
            return unless raise

            on_key_not_registered && on_key_not_registered.call(key)
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

      value = if value.respond_to?(:call) && call && !value.is_a?(NxtRegistry::Registry)
        value.call(*[value].take(value.arity))
      else
        value
      end

      if resolver
        resolver.call(value)
      else
        value
      end
    end

    def define_interface
      define_singleton_method name do |key = Blank.new, value = Blank.new|
        return self if key.is_a?(Blank)

        key = transformed_key(key)

        if value.is_a?(Blank)
          resolve(key)
        else
          register(key, value)
        end
      end

      define_singleton_method "#{name}!" do |key = Blank.new, value = Blank.new|
        return self if key.is_a?(Blank)

        key = transformed_key(key)

        if value.is_a?(Blank)
          resolve!(key)
        else
          register!(key, value)
        end
      end
    end

    def setup_defaults(options)
      @default = options.fetch(:default) { Blank.new }
      @memoize = options.fetch(:memoize) { true }
      @call = options.fetch(:call) { true }
      @resolver = options.fetch(:resolver, false)
      @transform_keys = options.fetch(:transform_keys) { ->(key) { key.to_s } }
      @on_key_already_registered = options.fetch(:on_key_already_registered) { ->(key) { raise_key_already_registered_error(key) } }
      @on_key_not_registered = options.fetch(:on_key_not_registered) { ->(key) { raise_key_not_registered_error(key) } }
    end

    def define_accessors
      %w[default memoize call resolver transform_keys on_key_already_registered on_key_not_registered].each do |attribute|
        define_singleton_method attribute do |value = Blank.new, &block|
          # TODO: Allowing a block does not make sense for memoize and call?!
          value = block if block

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

      attrs.keys.exclude?(transformed_key(key))
    end

    def resolve_default
      if call && default.respond_to?(:call)
        default.call
      else
        default
      end
    end

    def raise_key_already_registered_error(key)
      raise NxtRegistry::Errors::KeyAlreadyRegisteredError, "Key '#{key}' already registered in registry '#{namespace}'"
    end

    def raise_key_not_registered_error(key)
      raise NxtRegistry::Errors::KeyNotRegisteredError, "Key '#{key}' not registered in registry '#{namespace}'"
    end

    def transformed_key(key)
      @transformed_key ||= {}
      @transformed_key[key] ||= begin
        if transform_keys && !key.is_a?(Blank)
          transform_keys.call(key)
        else
          key
        end
      end
    end
  end
end
