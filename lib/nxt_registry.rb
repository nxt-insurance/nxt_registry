require 'active_support/all'
require "nxt_registry/version"
require "nxt_registry/blank"
require "nxt_registry/attribute"
require "nxt_registry/errors"
require "nxt_registry/nested_registry_builder"
require "nxt_registry/registry"
require "nxt_registry/recursive_registry"

module NxtRegistry
  def registry(name, &config)
    Registry.new(name, &config)
  end

  def recursive_registry(name, &config)
    RecursiveRegistry.new(name, &config)
  end
end
