require 'ostruct'

module Actionizer
  class Result < OpenStruct

    def initialize(initial_hash = {})
      @success = true
      super(initial_hash)
    end

    def success?
      @success
    end

    def failure?
      !@success
    end

    def fail
      @success = false
    end

  end
end
