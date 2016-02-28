require 'hashie'

module Actionizer
  class Result < Hashie::Mash

    def initialize
      @success = true
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
