module Actionizer
  class Inputs
    attr_reader :declared_params_by_method, :method

    def initialize
      @declared_params_by_method = {}
    end

    def check_for_param_error(method_name, params = {})
      # If no inputs_for was declared, don't do any checking
      return false if !declared_params_by_method.key?(method_name)

      params.each_key do |param|
        return "Param #{param} not declared" if !declared_params_by_method.fetch(method_name).include?(param)
      end

      declared_params_by_method.fetch(method_name, {}).each_pair do |param, attrs|
        return "Param #{param} can't be nil" if !attrs.fetch(:null) && params[param].nil?

        type = attrs.fetch(:type)

        # Type check if param was required, or if optional and passed in
        if attrs.fetch(:required) || params.include?(param)
          return "Param #{param} must descend from #{type}" if type && !(params[param].class <= type)
        end

        if attrs.fetch(:required) && !params.include?(param)
          return "Param #{param} is required for #{method_name}"
        end
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

    def add(param:, required:, opts:)
      if ![nil, true, false].include?(opts[:null])
        raise ArgumentError, 'Please specify either true or false for a null option'
      end

      if opts[:type] && opts[:type].class != Class
        raise ArgumentError, "Please specify a class for type: (#{opts[:type]} is not a class)"
      end

      @declared_params_by_method[method][param] = { required: required,
                                                    null: false == opts[:null] ? false : true,
                                                    type: opts.fetch(:type, nil) }
    end

    def no_params_declared?(method)
      declared_params_by_method.fetch(method, {}).empty?
    end

    def outside_inputs_for_block?
      method.nil?
    end

  end
end
