module Actionizer
  class Failure < StandardError
    attr_reader :result

    def initialize(msg, result)
      @result = result
      super msg
    end

  end
end
