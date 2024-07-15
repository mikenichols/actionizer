require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'simplecov'
require 'actionizer'
require 'pry'
