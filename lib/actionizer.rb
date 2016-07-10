require 'ostruct'
require 'actionizer/result'
require 'actionizer/failure'
require 'actionizer/version'
require 'actionizer/inputs'

module Actionizer
  attr_reader :input, :output

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def method_missing(method_name, *args, &block)
      instance = new(*args)

      if instance.respond_to?(method_name)
        error = defined_inputs.check_for_param_error(method_name, *args)
        raise ArgumentError, error if error

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

    def defined_inputs
      @defined_inputs ||= Actionizer::Inputs.new
    end

    def inputs_for(method)
      raise ArgumentError, 'inputs_for requires a block' if !block_given?

      defined_inputs.start(method)
      yield
      defined_inputs.end

      raise 'You must define at least one optional or required param' if defined_inputs.no_params_declared?(method)
    end

    def optional(param)
      raise 'You must call optional from inside an inputs_for block' if defined_inputs.outside_inputs_for_block?

      defined_inputs.add(param: param, required: false)
    end

    def required(param)
      raise 'You must call required from inside an inputs_for block' if defined_inputs.outside_inputs_for_block?

      defined_inputs.add(param: param, required: true)
    end
  end

  def initialize(initial_input = {})
    @input = OpenStruct.new(initial_input)
    @output = Actionizer::Result.new
  end

  def fail!(params = {})
    params.each_pair { |key, value| output[key] = value }

    output.fail

    raise Actionizer::Failure.new('Failed!', output)
  end

  # Allows you to call *_or_fail
  def method_missing(method_name, *args, &block)
    return super if !method_name.to_s.end_with?('_or_fail')

    action_class, *params = args
    underlying_method = method_name.to_s.chomp('_or_fail')

    if !action_class.respond_to?(underlying_method)
      raise ArgumentError, "#{action_class.name} must define ##{underlying_method}"
    end

    result = action_class.send(underlying_method, *params)

    if !result.respond_to?(:failure?)
      raise ArgumentError, "#{action_class.name}##{underlying_method}'s result must respond to :failure?"
    end

    errors = result.to_h.select { |k, _v| k.to_s.start_with? 'error' }
    errors[:error] = "Unknown: Your result doesn't respond to a method beginning with 'error'" if errors.empty?
    fail!(errors) if result.failure?

    result
  end

  def respond_to_missing?(method_name, _include_private = false)
    method_name.to_s.end_with?('_or_fail')
  end
end
