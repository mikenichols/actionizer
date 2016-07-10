require 'spec_helper'

describe Actionizer do
  describe 'inputs_for' do
    context 'when you use optional outside of an inputs_for block' do
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

    context 'when you use required outside of an inputs_for block' do
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

    context 'when there are no params defined' do
      let(:failing_class) do
        Class.new do
          include Actionizer
          inputs_for(:call) {}
          def call; end
        end
      end
      it 'raises an error' do
        expect { failing_class.call }.to raise_error(RuntimeError)
      end
    end

    context 'when called with params not specified in inputs_for' do
      let(:failing_class) do
        Class.new do
          include Actionizer
          inputs_for :call do
            optional :foo
          end
          def call; end
        end
      end
      it 'raises an error' do
        expect { failing_class.call(bar: 'oops') }.to raise_error(ArgumentError)
      end
    end

    context 'when not called with all required params' do
      let(:failing_class) do
        Class.new do
          include Actionizer
          inputs_for :call do
            required :foo
            required :bar
          end
          def call; end
        end
      end
      it 'raises an error' do
        expect { failing_class.call(foo: 'present') }.to raise_error(ArgumentError)
      end
    end

    context 'when called with all required params' do
      let(:succeeding_class) do
        Class.new do
          include Actionizer
          inputs_for :call do
            required :foo
            required :bar
          end
          def call; end
        end
      end
      it 'succeeds' do
        succeeding_class.call(foo: 'present', bar: 'also present')
      end
    end

    context 'when called with all required params and some optional params' do
      let(:succeeding_class) do
        Class.new do
          include Actionizer
          inputs_for :call do
            required :foo
            optional :bar
            optional :qux
          end
          def call; end
        end
      end
      it 'succeeds' do
        succeeding_class.call(foo: 'present', qux: 'here')
      end
    end
  end
end
