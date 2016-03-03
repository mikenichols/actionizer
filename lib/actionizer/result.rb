require 'hashie'

module Actionizer
  class Result < Hashie::Mash

    def initialize(initial_hash = {})
      @success = true

      initial_hash.each_pair { |key, value| self[key] = value }
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
