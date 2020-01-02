# NxtRegistry

NxtRegistry is a simple implementation of the container pattern. It allows you to register and resolve values.
It allows to register and resolve values in nested structures by allowing to nest registries into each other.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'nxt_registry'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install nxt_registry

## Usage

## Restrict attributes to a certain set

Use `attrs` to restrict which attributes can be registered on a specific level.

## Default values

Use `default` to register a default value that will be resolved in case an attribute was not registered.

## Block

When you register a block value that can be called, tt will automatically be called when you resolve the value. 
If that's not what you want, you can configure your registry (on each level) not to call blocks directly by defining `call false`

## Memoize

Values are memoized per default. Switch it off with `default false`

## Resolver

You can register a resolver block if you want to lay hands on your values after they have been resolved.

## Transform keys

NxtRegistry uses a plain ruby hash to store values internally. Per default all keys used are transformed with `&:to_s`.
Thus you can use symbols or strings to register and resolve values. If it's not what you want, switch it off with `transform_keys false`
or define your own key transformer by assigning a block `transform_keys ->(key) { key.upcase }`   
 

```ruby
class MyClass
  include NxtRegistry
  
  def passengers
    @passengers ||= begin
      registry :from do
        nested :to do
          nested :via do
            attrs :train, :car, :plane, :horse
            default -> { [] }
            memoize true 
            call true
            resolver ->(value) { value } # do something with your registered value here
            transform_keys ->(key) { key.upcase } # transform keys 
          end
        end
      end
    end
  end
end

subject = MyClass.new
subject.passengers.from(:a).to(:b).via(:train) # => []
subject.passengers.from(:a).to(:b).via(:train) << 'Andy'
subject.passengers.from(:a).to(:b).via(:car) << 'Lütfi'
subject.passengers.from(:a).to(:b).via(:plane) << 'Nils'
subject.passengers.from(:a).to(:b).via(:plane) << 'Rapha'
subject.passengers.from(:a).to(:b).via(:plane) # => ['Nils', 'Rapha']

subject.passengers.from(:a).to(:b).via(:hyperloop) # => KeyError


class MyClass
  extend NxtRegistry

  REGISTRY = registry(:errors) do 
    register(KeyError, ->(error) { puts 'KeyError handler' } )
  end
end

MyClass::REGISTRY.resolve(KeyError)
# KeyError handler
# => nil

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/nxt_registry.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
