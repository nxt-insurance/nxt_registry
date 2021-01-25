require 'active_support'
require 'active_support/core_ext'
require 'nxt_registry/version'
require 'nxt_registry/blank'
require 'nxt_registry/key'
require 'nxt_registry/errors'
require 'nxt_registry/registry_builder'
require 'nxt_registry/registry'
require 'nxt_registry/recursive_registry'
require 'nxt_registry/singleton'

module NxtRegistry
  def registry(name, **options, &config)
    build_registry(Registry, name, **options, &config)
  end

  def recursive_registry(name, **options, &config)
    build_registry(RecursiveRegistry, name, **options, &config)
  end

  private

  def build_registry(registry_class, name, **options, &config)
    registry = registries.resolve(name)

    if registry.present?
      if registry.configured
        return registry
      else
        raise_unconfigured_registry_accessed(name)
      end
    else
      registry = registry_class.new(name, **options, &config)
      registries.register(name, registry)
    end
  end

  def raise_unconfigured_registry_accessed(name)
    raise ArgumentError, "The registry #{name} must be configured before accessed!"
  end

  def registries
    @registries ||= Registry.new(:registries)
  end
end
