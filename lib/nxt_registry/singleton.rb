module NxtRegistry
  module Singleton
    include NxtRegistry

    def self.included(base)
      base.extend(self)
    end

    def registry(type = Registry, **options, &config)
      @registry ||= build_registry(type, self.class.name, **options, &config)
    end

    delegate_missing_to :registry
  end
end
