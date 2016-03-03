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

  context 'input' do
    it "makes passed-in values accessible on 'input'" do
      dummy_class.class_eval do
        def call
          raise RuntimeError unless input.foo == 'abc'
          raise RuntimeError unless input.bar == %w(do re mi)
        end
      end

      dummy_class.call(foo: 'abc', bar: %w(do re mi))
    end

    it 'allows an inputs block to define required and optional params'
  end

  context 'output' do
    it 'is an Actionizer::Result' do
      result = dummy_class.call
      expect(result).to be_an(Actionizer::Result)
    end
  end

  describe '#fail!' do
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

    it 'sets the output to be failure' do
      expect(result).to be_failure
    end

    it 'sets fields in the output that you pass into fail!' do
      expect(result.error).to eq('error message')
    end
  end

  describe '#call_and_check_failure!' do
    let(:success_action_class) do
      Class.new do
        include Actionizer
        def call; end
      end
    end
    let(:failure_action_class) do
      Class.new do
        include Actionizer
        def call
          fail!(error: 'inner error')
        end
      end
    end

    before do
      dummy_class.class_eval do
        def call
          call_and_check_failure!(input.first_class, foo: 'bar')
          input.second_class.call
        end
      end
    end

    it 'returns an Actionizer::Result' do
      result = dummy_class.new.call_and_check_failure!(success_action_class)
      expect(result).to be_an(Actionizer::Result)
    end

    context "when you don't pass a calls that includes Actionizer" do
      it 'raises an ArgumentError' do
        expect { dummy_class.new.call_and_check_failure!(Object) }.to raise_error(ArgumentError)
      end
    end

    context 'when the first action succeeds' do
      it 'proceeds normally and calls both classes' do
        expect(success_action_class).to receive(:call)
          .with(foo: 'bar').once.and_call_original
        expect(failure_action_class).to receive(:call).once

        dummy_class.call(first_class: success_action_class,
                         second_class: failure_action_class)
      end
    end

    context 'when the first action fails' do
      it 'calls fail! and passes on result.error and skips calling the second class' do
        expect(failure_action_class).to receive(:call)
          .with(foo: 'bar').once.and_call_original
        expect(success_action_class).not_to receive(:call)

        result = dummy_class.call(first_class: failure_action_class,
                                  second_class: success_action_class)

        expect(result).to be_failure
        expect(result.error).to eq('inner error')
      end
    end

  end
end
