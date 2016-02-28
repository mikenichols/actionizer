require 'actionizer/result'
require 'actionizer/version'

module Actionizer
  attr_reader :result

  def self.included(base)
    base.class_eval do
      extend ClassMethods
    end
  end

  module ClassMethods
    def call(inputs = {})
      new(inputs).tap(&:call).result
    end
  end

  def initialize(inputs = {})
    @result = Actionizer::Result.new

    inputs.each_pair do |key, value|
      instance_variable_set("@#{key}".to_sym, value)

      self.class.class_eval do
        attr_reader key
      end
    end
  end
end
