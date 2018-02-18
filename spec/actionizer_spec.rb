require 'spec_helper'

describe Actionizer do
  let(:dummy_class) do
    Class.new do
      include Actionizer
      def call; end
    end
  end

  it 'has a version number' do
    expect(Actionizer::VERSION).not_to be_nil
  end

  context 'when an instance method is defined on a class' do
    let(:class_with_execute) do
      Class.new do
        include Actionizer
        def execute; end
      end
    end

    it 'invokes the instance method when you invoke the class method' do
      expect_any_instance_of(class_with_execute).to receive(:execute)
      class_with_execute.execute
    end

    it 'correctly tells you it responds to the method name' do
      expect(class_with_execute.respond_to?(:execute)).to eq(true)
    end

    it "doesn't allow you to call undefined methods" do
      expect { class_with_execute.not_defined }.to raise_error(NoMethodError)
    end

    it 'is successful by default' do
      result = class_with_execute.execute
      expect(result).to be_success
    end
  end

  context 'input' do
    it "makes passed-in values accessible on 'input'" do
      dummy_class.class_eval do
        def call
          raise RuntimeError if input.foo != 'abc'
          raise RuntimeError if input.bar != %w[do re mi]
        end
      end

      dummy_class.call(foo: 'abc', bar: %w[do re mi])
    end
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

  describe '<METHOD>!' do
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
          input.first_class.call!(foo: 'bar')
          input.second_class.call
        end
      end
    end

    it 'returns an Actionizer::Result' do
      result = success_action_class.call!
      expect(result).to be_an(Actionizer::Result)
    end

    context 'when the first action succeeds' do
      it 'proceeds normally and calls both classes' do
        expect(success_action_class).to receive(:call!)
          .with(foo: 'bar').once.and_call_original
        expect(failure_action_class).to receive(:call).once

        result = dummy_class.call(first_class: success_action_class,
                                  second_class: failure_action_class)

        expect(result).to be_success
      end
    end

    context 'when the first action fails' do
      it 'calls fail! and passes on result.error and skips calling the second class' do
        expect(failure_action_class).to receive(:call!)
          .with(foo: 'bar').once.and_call_original
        expect(success_action_class).not_to receive(:call)

        result = dummy_class.call(first_class: failure_action_class,
                                  second_class: success_action_class)

        expect(result).to be_failure
        expect(result.error).to eq('inner error')
      end

      context 'and error response field begins with "error" but has additional characters' do
        let(:failure_action_class) do
          Class.new do
            include Actionizer
            def call
              fail!(errors_xxxxx: 'inner error')
            end
          end
        end

        it 'calls fail! and passes on result.errors_xxxxx and skips calling the second class' do
          expect(failure_action_class).to receive(:call!)
            .with(foo: 'bar').once.and_call_original
          expect(success_action_class).not_to receive(:call)

          result = dummy_class.call(first_class: failure_action_class,
                                    second_class: success_action_class)

          expect(result).to be_failure
          expect(result.errors_xxxxx).to eq('inner error')
        end
      end
    end

    context 'dynamic <METHOD>! invocation' do
      let(:class_with_find) do
        Class.new do
          include Actionizer
          def find; end
        end
      end

      it 'allows any <METHOD> to be called as <METHOD>!' do
        expect(class_with_find).to receive(:find!).with(id: 1234).and_call_original
        expect_any_instance_of(class_with_find).to receive(:find).and_call_original
        class_with_find.find!(id: 1234)
      end

      it 'responds to <METHOD> and <METHOD>!' do
        expect(class_with_find).to respond_to(:find)
        expect(class_with_find).to respond_to(:find!)
      end

      it "doesn't respond to just any '!' method" do
        expect(dummy_class.respond_to?(:whatever!)).to eq(false)
      end

      context "when there's a param error" do
        let(:defined_inputs_double) { double(check_for_param_error: 'oops') }

        it 'raises an Actionizer::Failure' do
          expect(class_with_find).to receive(:defined_inputs).and_return(defined_inputs_double)
          expect { class_with_find.find! }.to raise_error(Actionizer::Failure)
        end
      end
    end

  end
end
