module NxtRegistry
  class Registry
    def initialize(name = object_id.to_s, **options, &config)
      @options = options
      @name = name
      @parent = options[:parent]
      @is_leaf = true
      @namespace = build_namespace
      @config = config
      @store = {}
      @attrs = nil
      @configured = false

      setup_defaults(options)
      configure(&config) if block_given? || parent
    end

    attr_reader :name
    attr_accessor :configured

    def level(name, **options, &config)
      options = options.merge(parent: self)

      if is_a_blank?(default)
        self.is_leaf = false

        self.default = RegistryBuilder.new do
          Registry.new(name, **options, &config)
        end

        # Call the builder once to guarantee we do not create a registry with a broken setup
        default.call
      elsif default.is_a?(RegistryBuilder)
        raise ArgumentError, 'Multiple nestings on the same level'
      else
        raise ArgumentError, 'Default values cannot be defined on registries that nest others'
      end
    end

    def registry(name, **options, &config)
      opts = options.merge(parent: self)
      register(name, Registry.new(name, **opts, &config))
    end

    def registry!(name, **options, &config)
      opts = options.merge(parent: self)
      register!(name, Registry.new(name, **opts, &config))
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

    def register(key = Blank.new, value = Blank.new, **options, &block)
      if block_given?
        if is_a_blank?(value)
          registry(key, **options, &block)
        else
          raise_register_argument_error
        end
      else
        __register(key, value, raise_on_key_already_registered: true)
      end
    end

    def register!(key = Blank.new, value = Blank.new, **options, &block)
      if block_given?
        if is_a_blank?(value)
          registry!(key, **options, &block)
        else
          raise_register_argument_error
        end
      else
        __register(key, value, raise_on_key_already_registered: false)
      end
    end

    def resolve!(*keys)
      keys.inject(self) do |current_registry, key|
        current_registry.send(:__resolve, key, raise_on_key_not_registered: true)
      end
    end

    def resolve(*keys)
      keys.inject(self) do |current_registry, key|
        current_registry.send(:__resolve, key, raise_on_key_not_registered: false) || break
      end
    end

    def to_h
      store
    end

    def [](key)
      resolve!(key)
    end

    def []=(key, value)
      register(key, value)
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

    def fetch(key, *args, &block)
      store.fetch(transformed_key(key), *args, &block)
    end

    delegate :size, :values, :each, :freeze, to: :store

    def configure(&block)
      define_accessors
      define_interface
      attrs(*Array(options.fetch(:attrs, [])))

      if block.present?
        if block.arity == 1
          instance_exec(self, &block)
        else
          instance_exec(&block)
        end
      end

      self.configured = true
    end

    def to_s
      "Registry[#{name}] -> #{store.to_s}"
    end

    alias_method :inspect, :to_s

    private

    attr_reader :namespace, :parent, :config, :store, :options, :accessor
    attr_accessor :is_leaf

    def is_leaf?
      @is_leaf
    end

    def __register(key, value, raise_on_key_already_registered: true)
      key = transformed_key(key)

      raise ArgumentError, "Not allowed to register values in a registry that contains nested registries" unless is_leaf
      raise KeyError, "Keys are restricted to #{attrs.keys}" if attribute_not_allowed?(key)

      on_key_already_registered && on_key_already_registered.call(key) if store[key] && raise_on_key_already_registered

      store[key] = value
    end

    def __resolve(key, raise_on_key_not_registered: true)
      key = transformed_key(key)

      value = if is_leaf?
        if store.key?(key)
          store.fetch(key)
        else
          if is_a_blank?(default)
            return unless raise_on_key_not_registered

            on_key_not_registered && on_key_not_registered.call(key)
          else
            value = resolve_default(key)
            return value unless memoize

            store[key] ||= value
          end
        end
      else
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
      raise_invalid_accessor_name(accessor) if respond_to?(accessor)
      accessor_with_bang = "#{accessor}!"
      raise_invalid_accessor_name(accessor_with_bang) if respond_to?(accessor_with_bang)

      define_singleton_method accessor do |key = Blank.new, value = Blank.new|
        return self if is_a_blank?(key)

        key = transformed_key(key)

        if is_a_blank?(value)
          resolve(key)
        else
          register(key, value)
        end
      end

      define_singleton_method accessor_with_bang do |key = Blank.new, value = Blank.new|
        return self if is_a_blank?(key)

        key = transformed_key(key)

        if is_a_blank?(value)
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
      @accessor = options.fetch(:accessor) { name }

      @on_key_already_registered = options.fetch(:on_key_already_registered) { ->(key) { raise_key_already_registered_error(key) } }
      @on_key_not_registered = options.fetch(:on_key_not_registered) { ->(key) { raise_key_not_registered_error(key) } }
    end

    def define_accessors
      %w[default memoize call resolver transform_keys on_key_already_registered on_key_not_registered].each do |attribute|
        define_singleton_method attribute do |value = Blank.new, &block|
          value = block if block

          if is_a_blank?(value)
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

    def resolve_default(key)
      if call && default.respond_to?(:call)
        default.arity > 0 ? default.call(key) : default.call
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
        if transform_keys && !is_a_blank?(key)
          transform_keys.call(key)
        else
          key
        end
      end
    end

    def initialize_copy(original)
      super
      @store = original.send(:store).deep_dup
      @options = original.send(:options).deep_dup
    end

    def build_namespace
      parent ? name.to_s.prepend("#{parent.send(:namespace)}.") : name.to_s
    end

    def raise_register_argument_error
      raise ArgumentError, 'Either provide a key value pair or a block to register'
    end

    def is_a_blank?(value)
      value.is_a?(Blank)
    end

    def raise_invalid_accessor_name(name)
      raise ArgumentError, "#{self} already implements a method named: #{name}. Please choose a different accessor name"
    end
  end
end
