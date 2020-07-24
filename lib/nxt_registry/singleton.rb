module NxtRegistry
  module Singleton
    def self.extended(subclass)
      subclass.singleton_class.class_eval do
        default_name = (subclass.name || 'registry')

        define_method :registry do |name = default_name, **options, &block|
          @registry ||= NxtRegistry::Registry.new(name, **options, &block)
        end

        delegate_missing_to :registry

        define_method(:instance) { registry }
      end
    end
  end
end
