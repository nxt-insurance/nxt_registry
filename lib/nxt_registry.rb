require 'active_support/core_ext'
require "nxt_registry/version"
require "nxt_registry/blank"
require "nxt_registry/attribute"
require "nxt_registry/errors"
require "nxt_registry/layered_registry_builder"
require "nxt_registry/registry"
require "nxt_registry/recursive_registry"
require "nxt_registry/singleton"

module NxtRegistry
  def registry(name, **options, &config)
    Registry.new(name, **options, &config)
  end

  def recursive_registry(name, **options, &config)
    RecursiveRegistry.new(name, **options, &config)
  end
end
