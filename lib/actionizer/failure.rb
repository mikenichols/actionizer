module Actionizer
  class Failure < Exception
    attr_reader :output

    def initialize(msg = 'Failed!', output = Actionizer::Result.new.tap(&:fail))
      @output = output
      super msg
    end

  end
end
