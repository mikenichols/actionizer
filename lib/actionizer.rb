require 'actionizer/result'
require 'actionizer/failure'
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
    rescue Actionizer::Failure => af
      af.result
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

  def fail!(params = {})
    params.each_pair { |key, value| result[key] = value }

    result.fail

    raise Actionizer::Failure.new('Failed!', result)
  end

  def call_and_check_failure!(action_class, params = {})
    unless action_class.include? Actionizer
      raise ArgumentError, "#{action_class.name} must include Actionizer"
    end

    local_result = action_class.call(params)
    fail!(error: local_result.error) if local_result.failure?

    local_result
  end
end
