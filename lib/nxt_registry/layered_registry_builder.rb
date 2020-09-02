module NxtRegistry
  class LayeredRegistryBuilder < Proc
    def initialize(&block)
      super(&block)
    end
  end
end
