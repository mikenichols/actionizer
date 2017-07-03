# Actionizer

[![Gem Version](https://badge.fury.io/rb/actionizer.svg)](https://badge.fury.io/rb/actionizer)
[![Build Status](https://travis-ci.org/mikenichols/actionizer.svg?branch=master)](https://travis-ci.org/mikenichols/actionizer)
[![Test Coverage](https://codeclimate.com/github/mikenichols/actionizer/badges/coverage.svg)](https://codeclimate.com/github/mikenichols/actionizer/coverage)
[![Code Climate](https://codeclimate.com/github/mikenichols/actionizer/badges/gpa.svg)](https://codeclimate.com/github/mikenichols/actionizer)

## Turn your classes into small, modular, resuable Actions!

This gem is an implementation of the Interactor pattern. This pattern has also been called [Ports and Adapters](http://www.dossier-andreas.net/software_architecture/ports_and_adapters.html) or [Hexagonal Architecture](http://victorsavkin.com/post/42542190528/hexagonal-architecture-for-rails-developers) or [DCI (Data-Context-Interaction)](https://en.wikipedia.org/wiki/Data,_context_and_interaction) but the ideas are pretty much the same. Its goal is to provide a simple pattern for writing truly single-purpose classes. These classes are then easy to reason about, easy to test, and easy to change. They aren't coupled to all sorts of other parts of your system; they are self-contained and perform one and only one action.

This is not remotely a new or unique idea as there have been [many](http://blog.8thlight.com/uncle-bob/2011/11/22/Clean-Architecture.html) [awesome](http://jamesgolick.com/2010/3/14/crazy-heretical-and-awesome-the-way-i-write-rails-apps.html) [articles](http://jeffreypalermo.com/blog/the-onion-architecture-part-1/) and previous [projects](https://github.com/collectiveidea/interactor/) written to implement clean, modular classes. Uncle Bob even wrote a [great post](https://blog.8thlight.com/uncle-bob/2012/08/13/the-clean-architecture.html) highlighting similarities between the big architectural ideas of the last decade or so. While you should totally go read that article, I'll summarize it here for you. Your app is not your framework. It's super effective to decouple your business logic from your framework, database, UI, and third-party APIs.

I like to think of your business logic as being the "gooey center" of your app. That's where the most critical code lives. You want to keep it isolated from the details of databases, file systems, and networks. This inner layer should be so simple as to be boring because it's crucial to get it correct, so you want to make the code clean and simple, even stupid simple. `Actionizer` will help you write boring, stupid simple code.

### Installation

Add this line to your application's Gemfile:

```ruby
gem 'actionizer'
```

And then run:

    $ bundle install

### Basic usage

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

### Check result status with `success?` and `failure?`

Actions are successful by default:
```ruby
result = SuccessfulAction.call(id: 1234)

result.success?
#=> true
result.failure?
#=> false
```

You can simplify your controllers drastically having them simply check for `success?`
```ruby
class UserController < ApplicationController

  def create
    result = CreateUser.call(name: params.fetch(:name), email: params.fetch(:email))

    if result.success?
      render :dashboard, user: result.user
    else
      redirect_to :new, error: "Couldn't create user because #{result.error_reason}"
    end
  end

end
```

### Signal failure with `fail!`

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

When you fail an action with `fail!`, the result it returns will return true for `failure?` and false for `success?`.
```ruby
result = FailingAction.call(id: 1234)

result.success?
#=> false
result.failure?
#=> true
```

### Composing Actions

The most common way to use `Actionizer` is to compose small pieces of functionality (which can themselves be Actions) into larger pieces of functionality to give that sequence of Actions a name and simple interface. Say you want to create a user and send them a welcome email as part of the onboarding process. Then you might do something like this:
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

This code is self-documenting because there's no wiki or comments to read about what's going on here. The code is telling you exactly what's going on.

### Error-checking shorthand: `*_or_fail`

To automatically check for `failure?` and bubble up errors on failure, there's a shorthand: `<METHOD>_or_fail`. It works for any instance method defined on the class you specify.
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

### Explicitly declare your inputs with `inputs_for`

To more explicitly document the inputs to your Actions, you can use `inputs_for`.
```ruby
class CreateUser
  include Actionizer

  inputs_for(:call) do
    required :name
    required :email
    optional :phone_number
  end
  def call
    result = CreateUser.call(user_params)
  end

  private

  def user_params
    { name: input.name, email: input.email, phone_number: input.phone_number }.compact
  end
end
```

### Specifying types and nullable fields

You can now also optionally specify types and nullability for your inputs. For the `type:` option, any ruby class can be used.

```ruby
inputs_for(:call) do
  required :name, type: String, null: false
  required :email, null: false
  optional :phone_number, type: Integer
end
```

### `inputs_for` error handling

The action will fail immediately if any of the conditions are met:
- Any required param is not passed
- A param is passed that is not declared
- `nil` is passed for a param marked `null: false` (default is `null: true`)
- The class of the argument is not equal to or a subclass of the specified type

Using an `inputs_for` block is completely opt-in so if you don't provide it, no checking is performed.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests and `rubocop -D` to check for style errors. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mikenichols/actionizer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
