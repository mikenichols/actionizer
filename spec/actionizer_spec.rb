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
  end

  context 'output' do
    it 'is an Actionizer::Result' do
      result = dummy_class.call
      expect(result).to be_an(Actionizer::Result)
    end
  end

  describe 'inputs_for' do
    context 'when you use .optional outside of an inputs_for block' do
      let(:failing_class) do
        Class.new do
          include Actionizer
          optional :foo
          def call; end
        end
      end
      it 'raises an error' do
        expect { failing_class.call }.to raise_error(RuntimeError)
      end
    end

    context 'when you use .required outside of an inputs_for block' do
      let(:failing_class) do
        Class.new do
          include Actionizer
          required :foo
          def call; end
        end
      end
      it 'raises an error' do
        expect { failing_class.call }.to raise_error(RuntimeError)
      end
    end

    context 'when you define inputs for a non-existent method' do
      let(:failing_class) do
        Class.new do
          include Actionizer
          inputs_for :non_existent_method do
            optional :foo
          end
          def call; end
        end
      end
      it 'raises an error' do
        expect { failing_class.call }.to raise_error(RuntimeError)
      end
    end

    context 'when there are no inputs defined' do
      it 'raises an error'
    end

    context 'when called with arguments not specified in inputs_for' do
      it 'raises an error'
    end

    context 'when not called with all required arguments' do
      it 'raises an error'
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

  describe '#*_or_fail' do
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
          call_or_fail(input.first_class, foo: 'bar')
          input.second_class.call
        end
      end
    end

    it 'returns an Actionizer::Result' do
      result = dummy_class.new.call_or_fail(success_action_class)
      expect(result).to be_an(Actionizer::Result)
    end

    context "when you pass a class that doesn't implement the invoked method" do
      it 'raises an ArgumentError' do
        expect { dummy_class.new.call_or_fail(Object) }
          .to raise_error(ArgumentError, 'Object must define #call')
      end
    end

    context "when the result doesn't respond to :failure?" do
      let(:non_conforming_class) do
        Class.new do
          def self.call(_params, _arg2)
            { success: true }
          end

          def self.name
            'AnonymousClass'
          end
        end
      end

      it 'raises an ArgumentError' do
        expect { dummy_class.new.call_or_fail(non_conforming_class, 1, 2) }
          .to raise_error(ArgumentError, "AnonymousClass#call's result must respond to :failure?")
      end
    end

    context 'when the method returns nil' do
      let(:non_conforming_class) do
        Class.new do
          def self.call(_params, _arg2)
            nil
          end
        end
      end

      it 'raises an ArgumentError' do
        expect { dummy_class.new.call_or_fail(non_conforming_class, 1, 2) }
          .to raise_error(ArgumentError)
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
          expect(failure_action_class).to receive(:call)
            .with(foo: 'bar').once.and_call_original
          expect(success_action_class).not_to receive(:call)

          result = dummy_class.call(first_class: failure_action_class,
                                    second_class: success_action_class)

          expect(result).to be_failure
          expect(result.errors_xxxxx).to eq('inner error')
        end
      end
    end

    context 'dynamic <FOO>_or_fail invocation' do
      let(:class_with_find) do
        Class.new do
          include Actionizer
          def find; end
        end
      end

      it 'allows any method <FOO>_or_fail, as long as the class defines <FOO>' do
        expect(class_with_find).to receive(:find).with(id: 1234).and_call_original
        expect_any_instance_of(class_with_find).to receive(:find).and_call_original
        dummy_class.new.find_or_fail(class_with_find, id: 1234)
      end

      it 'correctly tells you it responds to the method' do
        expect(dummy_class.new.respond_to?(:whatever_or_fail)).to eq(true)
      end

      it 'still fails if you call a method not defined on the specified class' do
        expect(class_with_find).to receive(:nope).and_call_original
        expect { dummy_class.new.nope_or_fail(class_with_find) }.to raise_error(NoMethodError)
      end
    end

  end
end
