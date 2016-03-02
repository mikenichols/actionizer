require 'actionizer/result'
require 'actionizer/failure'
require 'actionizer/version'

module Actionizer
  attr_reader :output

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

  def initialize(inputs = {})
    @output = Actionizer::Result.new

    inputs.each_pair do |key, value|
      next if key.to_s == 'output'

      instance_variable_set("@#{key}".to_sym, value)

      self.class.class_eval do
        attr_reader key
      end
    end
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
