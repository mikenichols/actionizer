require 'spec_helper'

module Actionizer
  describe Result do
    let(:result) { described_class.new }

    describe '#initialize' do
      let(:initial_hash) { { foo: 'value' } }
      let(:result) { described_class.new(initial_hash) }

      it 'defaults to being successful' do
        expect(result).to be_success
      end

      it 'allows you to pass a hash' do
        expect(result.foo).to eq(initial_hash[:foo])
      end
    end

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
