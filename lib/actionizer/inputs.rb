module Actionizer
  class Inputs
    attr_reader :declared_params_by_method, :method

    def initialize
      @declared_params_by_method = {}
    end

    # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    def check_for_param_error(method_name, params = {})
      # If no inputs_for was declared, don't do any checking
      if !declared_params_by_method.key?(method_name)
        return false
      end

      params.each_key do |param|
        if !declared_params_by_method.fetch(method_name).include?(param)
          return "Param #{param} not declared"
        end
      end

      declared_params_by_method.fetch(method_name, {}).each_pair do |param, attrs|
        if !attrs.fetch(:null) && params.key?(param) && params.fetch(param).nil?
          return "Param #{param} can't be nil"
        end

        if attrs.fetch(:required) && !params.include?(param)
          return "Param #{param} is required for #{method_name}"
        end

        if !params.include?(param)
          next
        end

        type = attrs.fetch(:type)
        param_class = params[param].is_a?(Class) ? params[param] : params[param].class
        if type && !(param_class <= type)
          return "Param #{param} must descend from #{type}"
        end
      end

      false
    end
    # rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

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

      @declared_params_by_method[method][param] = { required:,
                                                    null: opts[:null] != false,
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
