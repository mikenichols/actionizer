# Actionizer

[![Build Status](https://travis-ci.org/mikenichols/actionizer.svg?branch=master)](https://travis-ci.org/mikenichols/actionizer)
[![Test Coverage](https://codeclimate.com/github/mikenichols/actionizer/badges/coverage.svg)](https://codeclimate.com/github/mikenichols/actionizer/coverage)
[![Code Climate](https://codeclimate.com/github/mikenichols/actionizer/badges/gpa.svg)](https://codeclimate.com/github/mikenichols/actionizer)

## Turn your classes into small, modular, resuable Actions!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'actionizer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install actionizer

## Usage

Here's how you define an Action:

```ruby
module Action
  module Users

    class Create
      include Actionizer

      def call
        # Do stuff here
        output.user = user
      end
    end

  end
end
```

You can immediately stop execution with the `fail!` method
```ruby
module Action
  module Users

    class Delete
      include Actionizer

      def call
        # Possibly failing code here
        fail!(error: "Nope, didn't work") if failure_condition

        # This code never runs
        output.foo = 'bar'
      end
    end

  end
end
```

Inputs are available on the `input` instance variable. Actions are invoked with the `call` method.
```ruby
module Action
  module Users

    class Onboard
      include Actionizer

      def call
        result = Action::Users::Create.call(name: input.name, email: input.email)
        fail!(error: result.error) if result.failure?

        result = Action::Users::SendWelcomeEmail.call(name: input.name, email: input.email)
        fail!(error: result.error) if result.failure?
      end
    end

  end
end
```

This pattern is so common, there's a shorthand: `call_and_check_failure!`
```ruby
module Action
  module Users

    class Onboard
      include Actionizer

      def call
        # This code is identical to the example above
        call_and_check_failure!(Action::Users::Create, name: input.name, email: input.email)
        call_and_check_failure!(Action::Users::SendWelcomeEmail, name: input.name, email: input.email)
      end
    end

  end
end
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests and `rubocop -D` to check for style errors. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mikenichols/actionizer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
