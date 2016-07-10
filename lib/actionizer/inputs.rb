module Actionizer
  class Inputs
    attr_reader :declared_params_by_method, :method

    def initialize
      @declared_params_by_method = {}
    end

    def check_for_param_error(method_name, params = {})
      # If no inputs_for was declared, don't do any checking
      return false unless declared_params_by_method.key?(method_name)

      params.each_key do |param|
        return "Param #{param} not declared" unless declared_params_by_method.fetch(method_name).include?(param)
      end

      declared_params_by_method.fetch(method_name, []).each_pair do |param, attrs|
        next unless attrs.fetch(:required)

        return "Param #{param} is required for #{method_name}" unless params.include?(param)
      end

      false
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
