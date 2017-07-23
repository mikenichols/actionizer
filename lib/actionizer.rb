require 'ostruct'
require 'actionizer/result'
require 'actionizer/failure'
require 'actionizer/version'
require 'actionizer/inputs'

module Actionizer
  attr_reader :input, :output
  attr_accessor :raise_on_failure

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def method_missing(method_name, *args, &block)
      instance = new(*args)

      if method_name.to_s.end_with?('!')
        method_name = method_name.to_s.chomp('!').to_sym
        instance.raise_on_failure = true
      end

      if instance.respond_to?(method_name)
        error = defined_inputs.check_for_param_error(method_name, *args)
        if error
          raise Actionizer::Failure.new('Failed.', Actionizer::Result.new(error: error).tap(&:fail))
        end

        instance.tap(&method_name).output
      else
        super
      end
    rescue Actionizer::Failure => af
      if instance.raise_on_failure
        raise af
      end

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
    @raise_on_failure = false
  end

  def fail!(params = {})
    params.each_pair { |key, value| output[key] = value }

    output.fail

    raise Actionizer::Failure.new('Failed!', output)
  end
end
