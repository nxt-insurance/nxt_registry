module NxtRegistry
  module Singleton
    include NxtRegistry

    def registry(**options, &config)
      build_registry(Registry, self.class.name, **options, &config)
    end

    def recursive_registry(**options, &config)
      build_registry(RecursiveRegistry, self.class.name, **options, &config)
    end

    delegate_missing_to :registry
  end
end
