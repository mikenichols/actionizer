module Actionizer
  class Failure < StandardError
    attr_reader :output

    def initialize(msg, output)
      @output = output
      super msg
    end

  end
end
