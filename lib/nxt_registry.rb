require 'active_support/core_ext'
require "nxt_registry/version"
require "nxt_registry/blank"
require "nxt_registry/attribute"
require "nxt_registry/errors"
require "nxt_registry/registry_builder"
require "nxt_registry/registry"
require "nxt_registry/recursive_registry"
require "nxt_registry/singleton"

module NxtRegistry
  def registry(name, **options, &config)
    @registries ||= {}
    return @registries.fetch(name) if @registries.key?(name)

    registry = Registry.new(name, **options, &config)
    reader = options.fetch(:reader) { true }
    options.delete(:reader)
    @registries[name] ||= registry if reader

    registry
  end

  def recursive_registry(name, **options, &config)
    RecursiveRegistry.new(name, **options, &config)
  end
end
