module NxtRegistry
  class Registry
    def initialize(name, **options, &config)
      @name = name
      @parent = options[:parent]
      @namespace = [parent, self].compact.map(&:name).join('.')
      @default_value = options.fetch(:default) { Blank.new }
      @memoize_value = options.fetch(:memoize) { true }
      @call_proc_value = options.fetch(:call) { true }
      @config = config
      @store = { }
      @allowed_attributes = nil
      @is_leaf = true

      configure
    end

    attr_reader :name

    def nested(name, **options, &config)
      options = options.merge(parent: self)

      if default_value.is_a?(Blank)
        self.is_leaf = false

        self.default_value = NestedRegistryBuilder.new do
          Registry.new(name, **options, &config)
        end

        default_value.call
      elsif default_value.is_a?(NestedRegistryBuilder)
        raise ArgumentError, "Multiple nestings on the same level"
      else
        raise ArgumentError, "Default values cannot be defined on registries that nest others"
      end
    end

    def attr(name)
      @allowed_attributes ||= {}
      raise KeyError, "Attribute #{name} already registered in #{namespace}" if allowed_attributes.has_key?(name)

      allowed_attributes[name] = Attribute.new(name, self)
    end

    def attrs(*args)
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

    private

    attr_reader :namespace, :parent, :config, :store, :allowed_attributes, :call_proc_value, :memoize_value
    attr_accessor :default_value, :is_leaf

    def is_leaf?
      @is_leaf
    end

    def __register(key, value, raise: true)
      raise ArgumentError, "Not allowed to register values in a registry that contains nested registries" unless is_leaf
      raise KeyError, "Keys are restricted to #{allowed_attributes.keys}" if attribute_not_allowed?(key)
      raise KeyError, "Key '#{key}' already registered in registry '#{namespace}'" if store.has_key?(key) && raise

      store[key] = value
    end

    def __resolve(key, raise: true)
      if is_leaf?
        if store.has_key?(key)
          store.fetch(key)
        else
          if default_value.is_a?(Blank)
            if raise
              raise KeyError, "Key '#{key}' not registered in registry '#{namespace}'"
            else
              nil
            end
          else
            value = resolve_default_value
            return value unless memoize_value

            store[key] ||= value
          end
        end
      else
        # Call nested registry builder when we are not a leaf
        store[key] ||= default_value.call
      end
    end

    def configure
      instance_exec(&config) if config.present?
      define_interface
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

    def attribute_not_allowed?(key)
      return unless allowed_attributes

      allowed_attributes.keys.exclude?(key)
    end

    def resolve_default_value
      if call_proc_value && default_value.respond_to?(:call)
        default_value.call
      else
        default_value
      end
    end
  end
end
