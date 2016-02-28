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

  context 'inputs' do
    it 'makes them accessible inside the instance' do
      dummy_class.class_eval do
        def call
          raise RuntimeError unless input1 == 'abc'
          raise RuntimeError unless input2 == %w(do re mi)
        end
      end

      dummy_class.call(input1: 'abc', input2: %w(do re mi))
    end

    it 'allows an inputs block to define required and optional params'
  end

  context 'result' do
    it 'is returned' do
      result = dummy_class.call
      expect(result).to be_an(Actionizer::Result)
    end

    it 'is successful by default' do
      result = dummy_class.call
      expect(result).to be_success
    end
  end

  describe 'fail!' do
    let(:result) { dummy_class.call }

    before do
      dummy_class.class_eval do
        def call
          fail!(error: 'error message')
          raise RuntimeError
        end
      end
    end

    it 'fails immediately' do
      dummy_class.call
    end

    it 'sets the result to be failure' do
      expect(result).to be_failure
    end

    it 'sets fields in the result that you pass into fail!' do
      expect(result.error).to eq('error message')
    end
  end
end
