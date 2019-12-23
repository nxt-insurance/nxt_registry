# NxtRegistry

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/nxt_registry`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

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

```ruby
class MyClass
  include NxtRegistry
  
  def passengers
    @passengers ||= begin
      registry :from do
        nested :to do
          nested :via, default: -> { [] }, memoize: true, call: true do
            attrs :train, :car, :plane, :horse
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
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/nxt_registry.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
