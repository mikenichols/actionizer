require "actionizer/version"

module Actionizer
  def self.included(base)
    base.class_eval do
      extend ClassMethods
    end
  end

  module ClassMethods
    def call
      new.call
    end
  end
end
