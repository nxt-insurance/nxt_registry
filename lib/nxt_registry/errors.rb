module NxtRegistry
  module Errors
    KeyAlreadyRegisteredError = Class.new(KeyError)
    KeyNotRegisteredError = Class.new(KeyError)
  end
end
