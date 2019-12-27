module NxtRegistry
  module Errors
    DuplicateKeyError = Class.new(KeyError)
    MissingKeyError = Class.new(KeyError)
  end
end
