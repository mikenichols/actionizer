require 'recursive_open_struct'

module Actionizer
  class Result < RecursiveOpenStruct

    def initialize(initial_hash = {})
      @success = true
      super(initial_hash, preserve_original_keys: true)
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
