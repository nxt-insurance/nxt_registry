module NxtRegistry
  class RegistryBuilder < Proc
    def initialize(&block)
      super(&block)
    end
  end
end
