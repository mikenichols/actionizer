require 'spec_helper'

describe Actionizer do
  let(:dummy_class) do
    Class.new do
      include Actionizer

      def call
      end
    end
  end

  it 'has a version number' do
    expect(Actionizer::VERSION).not_to be_nil
  end

  it 'invokes #call when you invoke .call' do
    expect_any_instance_of(dummy_class).to receive(:call)
    dummy_class.call
  end
end
