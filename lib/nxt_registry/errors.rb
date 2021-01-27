module NxtRegistry
  module Errors
    KeyAlreadyRegisteredError = Class.new(KeyError)
    KeyNotRegisteredError = Class.new(KeyError)
    RequiredKeyMissing = Class.new(KeyError)
    KeyNotAllowed = Class.new(KeyError)
  end
end
