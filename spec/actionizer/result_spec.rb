require 'spec_helper'

module Actionizer
  describe Result do
    let(:result) { described_class.new }

    it 'has a success? method' do
      expect(result).to respond_to(:success?)
    end

    it 'has a failure? method' do
      expect(result).to respond_to(:failure?)
    end

    it 'allows arbitrary fields to be set' do
      result.field = 'value'
      expect(result.field).to eq('value')
    end
  end
end
