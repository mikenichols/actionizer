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

    context 'when you pass in a key of result as input' do
      it 'does not overwrite it' do
        dummy_class.class_eval do
          def call
            raise RuntimeError if result == 'nope'
          end
        end

        dummy_class.call(result: 'nope')
      end
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

    it 'sets the result to be failure' do
      expect(result).to be_failure
    end

    it 'sets fields in the result that you pass into fail!' do
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
          call_and_check_failure!(first_class, foo: 'bar')
          second_class.call
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
