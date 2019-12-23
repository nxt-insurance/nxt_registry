module NxtRegistry
  class NestedRegistryBuilder < Proc
    def initialize(&block)
      super(&block)
    end
  end
end
