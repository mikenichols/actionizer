require 'actionizer/result'
require 'actionizer/failure'
require 'actionizer/version'

module Actionizer
  attr_reader :input, :output

  def self.included(base)
    base.class_eval do
      extend ClassMethods
    end
  end

  module ClassMethods
    def call(inputs = {})
      new(inputs).tap(&:call).output
    rescue Actionizer::Failure => af
      af.output
    end
  end

  def initialize(initial_input = {})
    @input = Hashie::Mash.new(initial_input)
    @output = Actionizer::Result.new
  end

  def fail!(params = {})
    params.each_pair { |key, value| output[key] = value }

    output.fail

    raise Actionizer::Failure.new('Failed!', output)
  end

  def call_and_check_failure!(action_class, params = {})
    unless action_class.include? Actionizer
      raise ArgumentError, "#{action_class.name} must include Actionizer"
    end

    result = action_class.call(params)
    fail!(error: result.error) if result.failure?

    result
  end
end
