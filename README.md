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

Include `Actionizer` in your class and define an instance method. That instance method will be automatically invoked when you call the class method of the same name. Any Action defined with `Actionizer` will automatically return a hash-like result you can check for `success?` or `failure?`.

Inputs are available on the `input` instance variable. Use `output` to set any variables you want returned in the result.

```ruby
class CreateUser
  include Actionizer

  def call
    # Some validation here...
    output.user = User.create(name: input.name)
  end
end
```

Actions are successful by default:
```ruby
result = SuccessfulAction.call(id: 1234)

result.success?
#=> true
result.failure?
#=> false
```

You can immediately stop execution with the `fail!` method.
```ruby
class DeleteAccount
  include Actionizer

  def run
    # Possibly failing code here
    fail!(error: "Nope, didn't work") if failure_condition

    # This code never runs
    output.foo = 'bar'
  end
end
```

When an action fails with `fail!`, the result it returns will return false for `success?` and true for `failure?`.
```ruby
result = FailingAction.call(id: 1234)

result.success?
#=> false
result.failure?
#=> true
```

The most common way to use Actionizer is to compose small pieces of functionality (which can themselves be Actions) into larger pieces of functionality to give that sequence of Actions a name and simple interface.
```ruby
class OnboardUser
  include Actionizer

  def call
    result = CreateUser.call(name: input.name, email: input.email)
    fail!(error: result.error) if result.failure?

    result = SendWelcomeEmail.deliver_now(name: input.name, email: input.email)
    fail!(error: result.error) if result.failure?
  end
end
```


This pattern is so common, there's a shorthand: `<METHOD>_or_fail`. It works for any instance method defined on the class you specify.
```ruby
class OnboardUser
  include Actionizer

  def call
    # This code is identical to the example above
    call_or_fail(CreateUser, name: input.name, email: input.email)
    deliver_now_or_fail(SendWelcomeEmail, name: input.name, email: input.email)
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
