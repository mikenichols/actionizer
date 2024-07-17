lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'actionizer/version'

Gem::Specification.new do |spec|
  spec.name          = 'actionizer'
  spec.version       = Actionizer::VERSION
  spec.authors       = ['Mike Nichols']
  spec.email         = ['mykphyre@yahoo.com']

  spec.summary       = 'Turn your classes into small, modular, reusable Actions'
  spec.homepage      = 'https://github.com/mikenichols/actionizer'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  unless spec.respond_to?(:metadata)
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.1', '< 4'

  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'codeclimate-test-reporter', '~> 0.5'
  spec.add_development_dependency 'pry-byebug', '~> 3.4'
  spec.add_development_dependency 'rake', '~> 11.3'
  spec.add_development_dependency 'rspec', '~> 3.5'
  spec.add_development_dependency 'rubocop', '0.52.1'
  spec.add_development_dependency 'simplecov', '~> 0.12'
end
