module Actionizer
  class Failure < Exception
    attr_reader :output

    def initialize(msg, output)
      @output = output
      super msg
    end

  end
end
