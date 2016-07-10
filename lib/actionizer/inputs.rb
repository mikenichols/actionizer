module Actionizer
  class Inputs
    attr_reader :declared_params_by_method, :method

    def initialize
      @declared_params_by_method = {}
    end

    def start(method)
      @method = method
      @declared_params_by_method[method] = {}
    end

    def end
      @method = nil
    end

    def add(args)
      @declared_params_by_method[method][args.fetch(:param)] = { required: args.fetch(:required) }
    end

    def no_params_declared?(method)
      declared_params_by_method.fetch(method, {}).empty?
    end

    def outside_inputs_for_block?
      method.nil?
    end

  end
end
