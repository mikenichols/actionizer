require 'spec_helper'

describe Actionizer::Failure do
  context 'when an action class rescues StandardError' do
    let(:dummy_class) do
      Class.new do
        include Actionizer
        def call
          fail!(error: 'error')
        rescue StandardError
          raise StandardError, 'Should not rescue from Actionizer::Failure'
        end
      end
    end
    let(:result) { dummy_class.call }

    it "doesn't stop the action from working properly" do
      expect(result).to be_failure
    end
  end

  context 'when created with no args' do
    let(:result) { described_class.new }

    it 'works and the result is failure by default' do
      expect(result.output).to be_failure
    end
  end
end
