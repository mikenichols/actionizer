require 'actionizer/result'
require 'actionizer/failure'
require 'actionizer/version'

module Actionizer
  attr_reader :input, :output

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def method_missing(method_name, *args, &block)
      instance = new(*args)

      if instance.respond_to?(method_name)
        instance.tap(&method_name).output
      else
        super
      end
    rescue Actionizer::Failure => af
      af.output
    end

    def respond_to_missing?(method_name, include_private = false)
      new.respond_to?(method_name, include_private)
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
