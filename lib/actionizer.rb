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
        if error
          return Actionizer::Result.new(error: error).tap(&:fail)
        end

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

    def optional(param, opts = {})
      define_input_param(false, param, opts)
    end

    def required(param, opts = {})
      define_input_param(true, param, opts)
    end

    private

    def define_input_param(required, param, opts)
      if defined_inputs.outside_inputs_for_block?
        raise "You must call #{required ? 'required' : 'optional'} from inside an inputs_for block"
      end

      defined_inputs.add(param: param, required: required, opts: opts)
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

    verify_result_is_conforming!(result, "#{action_class.name}##{underlying_method}")

    errors = result.to_h.select { |key, _value| key.to_s.start_with?('error') }
    fail!(errors) if result.failure?

    result
  end

  def respond_to_missing?(method_name, _include_private = false)
    method_name.to_s.end_with?('_or_fail')
  end

  private

  def verify_result_is_conforming!(result, class_and_method)
    raise ArgumentError, "#{class_and_method}'s result must respond to :to_h" if !result.respond_to?(:to_h)

    raise ArgumentError, "#{class_and_method}'s result must respond to :failure?" if !result.respond_to?(:failure?)
  end
end
