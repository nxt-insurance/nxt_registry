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
      @configured = false
      @patterns = []
      @config = config

      configure(&config)
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
      opts = conditionally_inherit_options(options)
      register(name, Registry.new(name, **opts, &config))
    end

    def registry!(name, **options, &config)
      opts = conditionally_inherit_options(options)
      register!(name, Registry.new(name, **opts, &config))
    end

    def required_keys(*keys)
      @required_keys ||= []
      return @required_keys if keys.empty?

      @required_keys += keys.map { |key| transformed_key(key) }
    end

    def allowed_keys(*keys)
      @allowed_keys ||= []
      return @allowed_keys if keys.empty?

      @allowed_keys += keys.map { |key| transformed_key(key) }
    end

    alias attrs allowed_keys # @deprecated

    def attr(key)
      allowed_keys(key) # @deprecated
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
      key = matching_key(key)
      store.fetch(key, *args, &block)
    end

    delegate :size, :values, :each, :freeze, to: :store

    def configure(&block)
      setup_defaults(options)
      define_accessors
      define_interface
      allowed_keys(*Array(options.fetch(:allowed_keys, [])))
      required_keys(*Array(options.fetch(:required_keys, [])))

      if block.present?
        if block.arity == 1
          instance_exec(self, &block)
        else
          instance_exec(&block)
        end
      end

      validate_required_keys_given
      self.configured = true
    end

    def to_s
      "Registry[#{name}] -> #{store.to_s}"
    end

    alias inspect to_s

    private

    attr_reader :namespace, :parent, :config, :store, :options, :accessor, :patterns
    attr_accessor :is_leaf, :interface_defined

    def conditionally_inherit_options(opts)
      base = opts.delete(:inherit_options) ? options : {}
      base.merge(opts).merge(parent: self)
    end

    def validate_required_keys_given
      required_keys.each do |key|
        next if store.key?(key)

        raise Errors::RequiredKeyMissing, "Required key '#{key}' missing in #{self}"
      end
    end

    def is_leaf?
      @is_leaf
    end

    def __register(key, value, raise_on_key_already_registered: true)
      key = if key.is_a?(Regexp)
        patterns << key
        key
      else
        transformed_key(key)
      end

      raise ArgumentError, "Not allowed to register values in a registry that contains nested registries" unless is_leaf
      raise KeyError, "Keys are restricted to #{allowed_keys}" if key_not_allowed?(key)

      on_key_already_registered && on_key_already_registered.call(key) if store[key] && raise_on_key_already_registered

      store[key] = value
    end

    def __resolve(key, raise_on_key_not_registered: true)
      key = transformed_key(key)

      value = if is_leaf?
        resolved_key = key_resolver.call(key)

        if store.key?(resolved_key)
          store.fetch(resolved_key)
        elsif (pattern = matching_pattern(resolved_key))
          store.fetch(pattern)
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

      value = call_or_value(value, key)

      resolver.call(value)
    end

    def matching_key(key)
      key = transformed_key(key)
      # if key is present it always wins over patterns
      return key if store.key?(key)

      matching_pattern(key) || key
    end

    def call_or_value(value, key)
      return value unless call
      return value if value.is_a?(NxtRegistry::Registry)
      return value unless value.respond_to?(:call)

      args = [key, value]
      value.call(*args.take(value.arity))
    end

    def matching_pattern(key)
      patterns.find { |pattern| key.match?(pattern) }
    end

    def define_interface
      return if interface_defined

      raise_invalid_accessor_name(accessor) if respond_to?(accessor.to_s)
      accessor_with_bang = "#{accessor}!"
      raise_invalid_accessor_name(accessor_with_bang) if respond_to?(accessor_with_bang)

      define_singleton_method accessor.to_s do |key = Blank.new, value = Blank.new|
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

      self.interface_defined = true
    end

    def setup_defaults(options)
      @default = options.fetch(:default) { Blank.new }
      @memoize = options.fetch(:memoize) { true }
      @call = options.fetch(:call) { true }
      @resolver = options.fetch(:resolver, ->(val) { val })
      @key_resolver = options.fetch(:key_resolver, ->(val) { val })
      @transform_keys = options.fetch(:transform_keys) { ->(key) { key.is_a?(Regexp) ? key : key.to_s } }
      @accessor = options.fetch(:accessor) { name }

      @on_key_already_registered = options.fetch(:on_key_already_registered) { ->(key) { raise_key_already_registered_error(key) } }
      @on_key_not_registered = options.fetch(:on_key_not_registered) { ->(key) { raise_key_not_registered_error(key) } }
    end

    def define_accessors
      %w[default memoize call resolver key_resolver transform_keys on_key_already_registered on_key_not_registered].each do |attribute|
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

    def key_not_allowed?(key)
      return if allowed_keys.empty?

      allowed_keys.exclude?(transformed_key(key))
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

    def initialize_copy(original)
      super

      containers = %i[store options]
      variables = %i[patterns required_keys allowed_keys namespace on_key_already_registered on_key_not_registered]

      containers.each { |c| instance_variable_set("@#{c}", original.send(c).deep_dup) }
      variables.each { |v| instance_variable_set("@#{v}", original.send(v).dup) }
    end
  end
end
