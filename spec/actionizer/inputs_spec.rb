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

      it 'fails gracefully and sets the error message' do
        result = failing_class.call(bar: 'oops')
        expect(result).to be_failure
        expect(result.error).to eq('Param bar not declared')
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

      it 'fails gracefully and sets the error message' do
        result = failing_class.call(foo: 'present')
        expect(result).to be_failure
        expect(result.error).to eq('Param bar is required for call')
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
        result = succeeding_class.call(foo: 'present', bar: 'also present')
        expect(result).to be_success
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
        result = succeeding_class.call(foo: 'present', qux: 'here')
        expect(result).to be_success
      end
    end

    context 'with persistence' do
      class DummyPersistence
        include Actionizer

        def find
          output.dummy = 'persistence_result'
        end
        def local_find
          output.dummy = 'local_persistence_result'
        end
      end

      context 'when persistence: is defined' do
        let(:succeeding_class) do
          Class.new do
            include Actionizer

            inputs_for :call do
              required :foo, persistence: DummyPersistence
            end
            def call
              output.lookup = input.foo
            end
          end
        end

        context 'when called with a string' do
          it 'looks up the id and succeeds' do
            expect(DummyPersistence).to receive(:find).with(id: 'an id')
            result = succeeding_class.call(foo: 'an id')
            expect(result).to be_success
            expect(result.lookup).to eq 'persistence_result'
          end
        end

        context 'when called with something else' do
          it 'passes it through' do
            expect(DummyPersistence).not_to receive(:find)
            result = succeeding_class.call(foo: { this: 'is not an id' })
            expect(result).to be_success
            expect(result.lookup).to eq(this: 'is not an id')
          end
        end
      end

      context 'when local_persistence: is defined' do
        let(:succeeding_class) do
          Class.new do
            include Actionizer

            inputs_for :call do
              required :foo, local_persistence: DummyPersistence
            end
            def call
              output.lookup = input.foo
            end
          end
        end

        context 'when called with a string' do
          it 'looks up the id and succeeds' do
            expect(DummyPersistence).to receive(:local_find).with(id: 'an id')
            result = succeeding_class.call(foo: 'an id')
            expect(result).to be_success
            expect(result.lookup).to eq 'local_persistence_result'
          end
        end

        context 'when called with something else' do
          it 'passes it through' do
            expect(DummyPersistence).not_to receive(:local_find)
            result = succeeding_class.call(foo: { this: 'is not an id' })
            expect(result).to be_success
            expect(result.lookup).to eq(this: 'is not an id')
          end
        end
      end
    end

    describe 'null option' do
      context 'when not specified' do
        let(:dummy_class) do
          Class.new do
            include Actionizer
            inputs_for(:call) do
              optional :foo
            end
            def call; end
          end
        end

        context 'and nothing is passed' do
          it 'succeeds' do
            expect(dummy_class.call).to be_success
          end
        end

        context 'and nil is passed' do
          it 'succeeds' do
            expect(dummy_class.call(foo: nil)).to be_success
          end
        end

        context 'and not nil is passed' do
          it 'succeeds' do
            expect(dummy_class.call(foo: 'not-nil')).to be_success
          end
        end
      end

      context 'when null is specified as true' do
        let(:dummy_class) do
          Class.new do
            include Actionizer
            inputs_for(:call) do
              optional :foo, null: true
            end
            def call; end
          end
        end

        context 'and nothing is passed' do
          it 'succeeds' do
            expect(dummy_class.call).to be_success
          end
        end

        context 'and nil is passed' do
          it 'succeeds' do
            expect(dummy_class.call(foo: nil)).to be_success
          end
        end

        context 'and not nil is passed' do
          it 'succeeds' do
            expect(dummy_class.call(foo: 'not-nil')).to be_success
          end
        end
      end

      context 'when null is specified as false' do
        let(:dummy_class) do
          Class.new do
            include Actionizer
            inputs_for(:call) do
              optional :foo, null: false
            end
            def call; end
          end
        end

        context 'and nothing is passed' do
          it 'succeeds' do
            expect(dummy_class.call).to be_success
          end
        end

        context 'and nil is passed' do
          it 'fails gracefully and sets the error message' do
            result = dummy_class.call(foo: nil)
            expect(result).to be_failure
            expect(result.error).to eq("Param foo can't be nil")
          end
        end

        context 'and not nil is passed' do
          it 'succeeds' do
            expect(dummy_class.call(foo: 'not-nil')).to be_success
          end
        end
      end

      context 'when null is specified as something other than true or false' do
        let(:dummy_class) do
          Class.new do
            include Actionizer
            inputs_for(:call) do
              optional :foo, null: 'not-true-or-false'
            end
            def call; end
          end
        end

        it 'raises an ArgumentError' do
          expect { dummy_class.call(foo: 'whatever') }.to raise_error(ArgumentError)
        end
      end
    end

    describe 'type option' do
      context 'when no type is specified' do
        let(:dummy_class) do
          Class.new do
            include Actionizer
            inputs_for(:call) do
              optional :foo
            end
            def call; end
          end
        end

        it 'allows any type' do
          expect(dummy_class.call(foo: :any_type_at_all)).to be_success
        end
      end

      context 'when a type is specified' do
        let(:dummy_class) do
          Class.new do
            include Actionizer
            inputs_for(:call) do
              optional :foo, type: Numeric
            end
            def call; end
          end
        end

        context 'and that exact type is passed' do
          it 'succeeds' do
            expect(dummy_class.call(foo: 1)).to be_success
          end
        end

        context 'and a subclass of that type is passed' do
          it 'succeeds' do
            expect(dummy_class.call(foo: 1.1)).to be_success
          end
        end

        context 'and a type other than a subclass is passed' do
          it 'fails gracefully and sets the error message' do
            result = dummy_class.call(foo: '1')
            expect(result).to be_failure
            expect(result.error).to eq('Param foo must descend from Numeric')
          end
        end

        context 'and the type specified is a parent class' do
          context 'and the arg passed is a descendent' do
            it 'succeeds' do
              expect(dummy_class.call(foo: Integer)).to be_success
            end
          end

          context 'and the arg passed is not a descendent' do
            it 'fails' do
              result = dummy_class.call(foo: String)
              expect(result).to be_failure
              expect(result.error).to eq('Param foo must descend from Numeric')
            end
          end
        end

        context 'and nil is passed' do
          it 'fails because of the type check, not because of the nil check' do
            result = dummy_class.call(foo: nil)
            expect(result).to be_failure
            expect(result.error).to eq('Param foo must descend from Numeric')
          end
        end

        context 'and that thing is not a class' do
          let(:dummy_class) do
            Class.new do
              include Actionizer
              inputs_for(:call) do
                optional :foo, type: 'not-a-class'
              end
              def call; end
            end
          end

          it 'raises an ArgumentError' do
            expect { dummy_class.call(foo: 'whatever') }.to raise_error(ArgumentError)
          end
        end
      end

      context 'when a type is specified with null: true' do
        let(:dummy_class) do
          Class.new do
            include Actionizer
            inputs_for(:call) do
              optional :foo, type: String, null: true
            end
            def call; end
          end
        end

        context 'when no arg is passed' do
          let(:result) { dummy_class.call }

          it 'succeeds' do
            expect(result).to be_success
          end
        end
      end
    end # type option
  end
end
