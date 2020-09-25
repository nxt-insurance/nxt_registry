require 'active_support/core_ext'
require 'nxt_registry/version'
require 'nxt_registry/blank'
require 'nxt_registry/attribute'
require 'nxt_registry/errors'
require 'nxt_registry/registry_builder'
require 'nxt_registry/registry'
require 'nxt_registry/recursive_registry'

module NxtRegistry
  def registry(name, **options, &config)
    build_registry(Registry, name, **options, &config)
  end

  def recursive_registry(name, **options, &config)
    build_registry(RecursiveRegistry, name, **options, &config)
  end

  private

  def build_registry(registry_class, name, **options, &config)
    return registries.fetch(name) if registries.key?(name)

    registry = registry_class.new(name, **options, &config)
    registries[name] ||= registry
    registry
  end

  def registries
    @registries ||= {}
  end
end
