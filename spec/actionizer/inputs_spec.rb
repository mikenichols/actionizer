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

    describe 'null option' do
      context 'when not specified' do
        let(:dummy_class) do
          Class.new do
            include Actionizer
            inputs_for(:call) do
              optional :arg
            end
            def call; end
          end
        end

        context 'and nil is passed' do
          it 'succeeds' do
            expect(dummy_class.call(arg: nil)).to be_success
          end
        end

        context 'and not nil is passed' do
          it 'succeeds' do
            expect(dummy_class.call(arg: 'not-nil')).to be_success
          end
        end
      end

      context 'when null is specified as true' do
        let(:dummy_class) do
          Class.new do
            include Actionizer
            inputs_for(:call) do
              optional :arg, null: true
            end
            def call; end
          end
        end

        context 'and nil is passed' do
          it 'succeeds' do
            expect(dummy_class.call(arg: nil)).to be_success
          end
        end

        context 'and not nil is passed' do
          it 'succeeds' do
            expect(dummy_class.call(arg: 'not-nil')).to be_success
          end
        end
      end

      context 'when null is specified as false' do
        let(:dummy_class) do
          Class.new do
            include Actionizer
            inputs_for(:call) do
              optional :arg, null: false
            end
            def call; end
          end
        end

        context 'and nil is passed' do
          it 'fails' do
            expect { dummy_class.call(arg: nil) }.to raise_error(ArgumentError)
          end
        end

        context 'and not nil is passed' do
          it 'succeeds' do
            expect(dummy_class.call(arg: 'not-nil')).to be_success
          end
        end
      end

      context 'when null is specified as something other than true or false' do
        let(:dummy_class) do
          Class.new do
            include Actionizer
            inputs_for(:call) do
              optional :arg, null: 'not-true-or-false'
            end
            def call; end
          end
        end

        it 'raises an ArgumentError' do
          expect { dummy_class.call(arg: 'whatever') }.to raise_error(ArgumentError)
        end
      end
    end

    describe 'type option' do
      context 'when no type is specified' do
        let(:dummy_class) do
          Class.new do
            include Actionizer
            inputs_for(:call) do
              optional :arg
            end
            def call; end
          end
        end

        it 'allows any type' do
          expect(dummy_class.call(arg: :any_type_at_all)).to be_success
        end
      end

      context 'when a type is specified' do
        let(:dummy_class) do
          Class.new do
            include Actionizer
            inputs_for(:call) do
              optional :arg, type: Numeric
            end
            def call; end
          end
        end

        context 'and that exact type is passed' do
          it 'succeeds' do
            expect(dummy_class.call(arg: 1)).to be_success
          end
        end

        context 'and a subclass of that type is passed' do
          it 'succeeds' do
            expect(dummy_class.call(arg: 1.1)).to be_success
          end
        end

        context 'and a type other than a subclass is passed' do
          it 'fails' do
            expect { dummy_class.call(arg: '1') }.to raise_error(ArgumentError)
          end
        end

        context 'and that thing is not a class' do
          let(:dummy_class) do
            Class.new do
              include Actionizer
              inputs_for(:call) do
                optional :arg, type: 'not-a-class'
              end
              def call; end
            end
          end

          it 'raises an ArgumentError' do
            expect { dummy_class.call(arg: 'whatever') }.to raise_error(ArgumentError)
          end
        end
      end
    end

  end
end
