[![CircleCI](https://circleci.com/gh/nxt-insurance/nxt_registry.svg?style=svg)](https://circleci.com/gh/nxt-insurance/nxt_registry)

# NxtRegistry

NxtRegistry is a simple implementation of the container pattern. It allows you to register and resolve values in nested 
structures by allowing nesting registries into each other. In theory this can be indefinitely deep.

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

### Instance Level

```ruby
class Example
  include NxtRegistry
  
  def languages
    @languages ||= begin
      registry :languages do
        register(:ruby, 'Stone')
        register(:python, 'Snake')
        register(:javascript, 'undefined')
      end
    end
  end
end

example = Example.new
example.languages.resolve(:ruby) # => 'Stone'
```

Alternatively you can create an instance of NxtRegistry::Registry.new('name', **options, &config)

```ruby
registry = NxtRegistry::Registry.new do
  register(:andy, 'Andy')
  register(:anthony, 'Anthony')
  register(:aki, 'Aki')
end

registry.resolve(:aki) # => 'Aki'

```

### Class Level

By extending NxtRegistry::Singleton you get a super simple class level interface to an underlying instance of a :registry.

```ruby
class SimpleExample
  extend NxtRegistry::Singleton
  
  registry do
    register(KeyError, ->(error) { puts 'KeyError handler' } )
    register(ArgumentError, ->(error) { puts 'ArgumentError handler' } )
    
    on_key_already_registered ->(key) { raise "Key was already registered dude: #{key}" }
    on_key_not_registered ->(key) { raise "Key was never registered dude: #{key}" }
  end
end
  
SimpleExample.resolve(KeyError)
# Alternatively: SimpleExample.registry.resolve(KeyError) 
# Or: SimpleExample.instance.resolve(KeyError) 
# KeyError handler
# => nil

```

```ruby
class OtherExample
  extend NxtRegistry
 
  REGISTRY = registry(:errors) do
    register(KeyError, ->(error) { puts 'KeyError handler' } )
    register(ArgumentError, ->(error) { puts 'ArgumentError handler' } )
  end
end

# Instead of using the name of the registry, you can also always call register and resolve on the 
# level where you want to register or resolve values. Equivalently to the named interface you can 
# use register! and resolve! to softly resolve or forcfully register values.  
OtherExample::REGISTRY.resolve(KeyError)
# KeyError handler
# => nil

```
### Nested registries

You can also simply nest registries into each other

```ruby
class Nested
  extend NxtRegistry::Singleton

  registry :developers do
    registry(:frontend) do
      register(:igor, 'Igor')
      register(:ben, 'Ben')
    end
    
    registry(:backend) do
      register(:rapha, 'Rapha')
      register(:aki, 'Aki')
    end
  end
end
```

Nested.registry.resolve(:frontend).resolve(:igor)

### Restrict attributes to a certain set

Use `attrs` to restrict which attributes can be registered on a specific level.

```ruby
registry :example, attrs: %w[one two three]
```

### Default values

Use `default` to register a default value that will be resolved in case an attribute was not registered.

```ruby
registry :example, default: ->(value) { 'default' }
```

### Blocks

When you register a block value that can be called, it will automatically be called when you resolve the value. 
If that's not what you want, you can configure your registry (on each level) not to call blocks directly by defining `call false`

```ruby
registry :example, call: false do
  register(:one, ->(value) { 'Not called when resolved' } )
end
```

### Memoize

Values are memoized per default. Switch it off with `memoize: false`

```ruby
registry :example, memoize: false do
  register(:one, -> { Time.current } )
end

registry.resolve(:one)
# => 2020-01-02 23:56:15 +0100
registry.resolve(:one)
# => 2020-01-02 23:56:17 +0100
registry.resolve(:one)
# => 2020-01-02 23:56:18 +0100
```

### Resolver

You can register a resolver block if you want to lay hands on your values after they have been resolved. 
A resolver can be anything that implements `:call` to which the value is passed.  

```ruby
registry :example do
  resolver ->(value) { value * 2 }
  register(:one, 1)
end

registry.resolve(:one)
# => 2
```

### Transform keys

NxtRegistry uses a plain ruby hash to store values internally. Per default all keys used are transformed with `&:to_s`.
Thus you can use symbols or strings to register and resolve values. If it's not what you want, switch it off with `transform_keys false`
or define your own key transformer by assigning a block to transform_keys: `transform_keys ->(key) { key.upcase }`

```ruby
registry :example do
  transform_keys ->(key) { key.to_s.downcase }
  register(:bombshell, 'hanna')
end

registry.resolve('BOMBSHELL')
# => 'hanna'
```

### Customize registry errors

You can also customize what kind of errors are being raised in case a of a key was not registered or was already registered.
by providing blocks or a handler responding to :call for `on_key_already_registered` and `on_key_already_registered`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/nxt_registry.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
