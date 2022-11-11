# frozen_string_literal: true

module NxtRegistry
  module StubMixin # rubocop:disable Style/Documentation
    def enable_stubs!
      singleton_class.prepend(::NxtRegistry::Stub)
    end
  end

  module Stub # rubocop:disable Style/Documentation
    def enable_stubs!; end

    def resolve(*keys)
      _stub_map.fetch(keys.join('.')) { super }
    end
    alias _parent_resolve resolve
    alias resolve! resolve

    def stub(*keys, value:)
      raise ArgumentError, "registry does not contain this key: #{keys}" unless _parent_resolve(*keys)

      key = keys.join('.')
      _stub_map[key] = value

      value
    end

    def unstub
      @_stub_map = {}
    end

    private

    def _stub_map
      @_stub_map ||= {}
    end
  end
end

NxtRegistry::Registry.include(NxtRegistry::StubMixin)
