require File.dirname(__FILE__) + '/../../spec_helper'

module Spec
  module DSL
    class FakeReporter < Spec::Runner::Reporter
      attr_reader :added_behaviour
      def add_behaviour(description)
        @added_behaviour = description
      end
    end

    describe Example, :shared => true do
      before :each do
        @options = ::Spec::Runner::Options.new(StringIO.new, StringIO.new)
        @options.formatters << mock("formatter", :null_object => true)
        @options.backtrace_tweaker = mock("backtrace_tweaker", :null_object => true)
        @reporter = FakeReporter.new(@options)
        @options.reporter = @reporter
        @behaviour = Class.new(Example).describe("example") do
          it "does nothing"
        end
        @behaviour.rspec_options = @options
      end

      after :each do
        Example.clear_before_and_after!
      end
    end

    describe "Example", ".suite" do
      it_should_behave_like "Spec::DSL::Example"

      it "returns an empty ExampleSuite when there is no description" do
        Example.description.should be_nil
        Example.suite.should be_instance_of(ExampleSuite)
        Example.suite.tests.should be_empty
      end

      it "returns an ExampleSuite with Examples"
    end

    describe "Example", ".description" do
      it_should_behave_like "Spec::DSL::Example"

      it "should return the same description instance for each call" do
        @behaviour.description.should eql(@behaviour.description)
      end
    end

    describe "Example", ".run" do
      it_should_behave_like "Spec::DSL::Example"

      it "should not run before(:all) or after(:all) on dry run" do
        @options.dry_run = true
        before_all_ran = false
        after_all_ran = false
        Example.before(:all) { before_all_ran = true }
        Example.after(:all) { after_all_ran = true }
        @behaviour.it("should") {}
        @behaviour.run
        before_all_ran.should be_false
        after_all_ran.should be_false
      end

      it "should not run any example if before(:all) fails" do
        spec_ran = false
        Example.before(:all) { raise NonStandardError }
        @behaviour.it("test") {spec_ran = true}
        @behaviour.run
        spec_ran.should be_false
      end

      it "should run after(:all) if before(:all) fails" do
        after_all_ran = false
        Example.before(:all) { raise NonStandardError }
        Example.after(:all) { after_all_ran = true }
        @behaviour.run
        after_all_ran.should be_true
      end

      it "should run after(:all) if before(:each) fails" do
        after_all_ran = false
        Example.before(:each) { raise NonStandardError }
        Example.after(:all) { after_all_ran = true }
        @behaviour.run
        after_all_ran.should be_true
      end

      it "should run after(:all) if any example fails" do
        after_all_ran = false
        @behaviour.it("should") { raise NonStandardError }
        Example.after(:all) { after_all_ran = true }
        @behaviour.run
        after_all_ran.should be_true
      end

      it "should run second after(:each) block even if the first one fails" do
        example = @behaviour.it("example") {}
        second_after_ran = false
        @behaviour.after(:each) do
          second_after_ran = true
          raise "second"
        end
        first_after_ran = false
        @behaviour.after(:each) do
          first_after_ran = true
          raise "first"
        end

        @reporter.should_receive(:example_finished) do |example, error, location, example_not_implemented|
          example.should equal(example)
          error.message.should eql("first")
          location.should eql("after(:each)")
          example_not_implemented.should be_false
        end
        @behaviour.run
        first_after_ran.should be_true
        second_after_ran.should be_true
      end

      it "should not run second before(:each) if the first one fails" do
        @behaviour.it("example") {}
        first_before_ran = false
        @behaviour.before(:each) do
          first_before_ran = true
          raise "first"
        end
        second_before_ran = false
        @behaviour.before(:each) do
          second_before_ran = true
          raise "second"
        end

        @reporter.should_receive(:example_finished) do |name, error, location, example_not_implemented|
          name.should eql("example")
          error.message.should eql("first")
          location.should eql("before(:each)")
          example_not_implemented.should be_false
        end
        @behaviour.run
        first_before_ran.should be_true
        second_before_ran.should be_false
      end

      it "should supply before(:all) as description if failure in before(:all)" do
        @reporter.should_receive(:example_finished) do |example, error, location|
          example.description.should eql("before(:all)")
          error.message.should == "in before(:all)"
          location.should eql("before(:all)")
        end

        Example.before(:all) { raise NonStandardError.new("in before(:all)") }
        @behaviour.it("test") {true}
        @behaviour.run
      end

      it "should provide after(:all) as description if failure in after(:all)" do
        @reporter.should_receive(:example_finished) do |example, error, location|
          example.description.should eql("after(:all)")
          error.message.should eql("in after(:all)")
          location.should eql("after(:all)")
        end

        Example.after(:all) { raise NonStandardError.new("in after(:all)") }
        @behaviour.run
      end

      it "should send reporter add_behaviour" do
        @behaviour.run
        @reporter.added_behaviour.should == "example"
      end

      it "should run example on run" do
        example_ran = false
        @behaviour.it("should") {example_ran = true}
        @behaviour.run
        example_ran.should be_true
      end

      it "should not run example on dry run" do
        example_ran = false
        @options.dry_run = true
        @behaviour.it("should") {example_ran = true}
        @behaviour.run
        example_ran.should be_false
      end

      it "should not run before(:all) or after(:all) on dry run" do
        @options.dry_run = true
        before_all_ran = false
        after_all_ran = false
        @behaviour.before(:all) { before_all_ran = true }
        @behaviour.after(:all) { after_all_ran = true }
        @behaviour.it("should") {}
        @behaviour.run
        before_all_ran.should be_false
        after_all_ran.should be_false
      end

      it "should not run any example if before(:all) fails" do
        spec_ran = false
        @behaviour.before(:all) { raise "help" }
        @behaviour.it("test") {spec_ran = true}
        @behaviour.run
        spec_ran.should be_false
      end

      it "should run after(:all) if before(:all) fails" do
        after_all_ran = false
        @behaviour.before(:all) { raise }
        @behaviour.after(:all) { after_all_ran = true }
        @behaviour.run
        after_all_ran.should be_true
      end

      it "should run after(:all) if before(:each) fails" do
        after_all_ran = false
        @behaviour.before(:each) { raise }
        @behaviour.after(:all) { after_all_ran = true }
        @behaviour.run
        after_all_ran.should be_true
      end

      it "should run after(:all) if any example fails" do
        after_all_ran = false
        @behaviour.it("should") { raise "before all error" }
        @behaviour.after(:all) { after_all_ran = true }
        @behaviour.run
        after_all_ran.should be_true
      end

      it "should supply before(:all) as description if failure in before(:all)" do
        @reporter.should_receive(:example_finished) do |example, error, location|
          example.description.should eql("before(:all)")
          error.message.should eql("in before(:all)")
          location.should eql("before(:all)")
        end

        @behaviour.before(:all) { raise "in before(:all)" }
        @behaviour.it("test") {true}
        @behaviour.run
      end

      it "should provide after(:all) as description if failure in after(:all)" do
        @reporter.should_receive(:example_finished) do |example, error, location|
          example.description.should eql("after(:all)")
          error.message.should eql("in after(:all)")
          location.should eql("after(:all)")
        end

        @behaviour.after(:all) { raise "in after(:all)" }
        @behaviour.run
      end

      it "should run before(:all) block only once" do
        before_all_run_count_run_count = 0
        @behaviour.before(:all) {before_all_run_count_run_count += 1}
        @behaviour.it("test") {true}
        @behaviour.it("test2") {true}
        @behaviour.run
        before_all_run_count_run_count.should == 1
      end

      it "should run after(:all) block only once" do
        after_all_run_count = 0
        @behaviour.after(:all) {after_all_run_count += 1}
        @behaviour.it("test") {true}
        @behaviour.it("test2") {true}
        @behaviour.run
        after_all_run_count.should == 1
        @reporter.rspec_verify
      end

      it "after(:all) should have access to all instance variables defined in before(:all)" do
        context_instance_value_in = "Hello there"
        context_instance_value_out = ""
        @behaviour.before(:all) { @instance_var = context_instance_value_in }
        @behaviour.after(:all) { context_instance_value_out = @instance_var }
        @behaviour.it("test") {true}
        @behaviour.run
        context_instance_value_in.should == context_instance_value_out
      end

      it "should copy instance variables from before(:all)'s execution context into spec's execution context" do
        context_instance_value_in = "Hello there"
        context_instance_value_out = ""
        @behaviour.before(:all) { @instance_var = context_instance_value_in }
        @behaviour.it("test") {context_instance_value_out = @instance_var}
        @behaviour.run
        context_instance_value_in.should == context_instance_value_out
      end

      it "should not add global before callbacks for untargetted behaviours" do
        fiddle = []

        Example.before(:all) { fiddle << "Example.before(:all)" }
        Example.prepend_before(:all) { fiddle << "Example.prepend_before(:all)" }
        Example.before(:each, :behaviour_type => :special) { fiddle << "Example.before(:each, :behaviour_type => :special)" }
        Example.prepend_before(:each, :behaviour_type => :special) { fiddle << "Example.prepend_before(:each, :behaviour_type => :special)" }
        Example.before(:all, :behaviour_type => :special) { fiddle << "Example.before(:all, :behaviour_type => :special)" }
        Example.prepend_before(:all, :behaviour_type => :special) { fiddle << "Example.prepend_before(:all, :behaviour_type => :special)" }

        behaviour = Class.new(Example).describe("I'm not special", :behaviour_type => :not_special) do
          it "does nothing"
        end
        behaviour.rspec_options = ::Spec::Runner::Options.new(StringIO.new, StringIO.new)
        behaviour.run
        fiddle.should == [
          'Example.prepend_before(:all)',
          'Example.before(:all)',
        ]
      end

      it "should add global before callbacks for targetted behaviours" do
        fiddle = []

        Example.before(:all) { fiddle << "Example.before(:all)" }
        Example.prepend_before(:all) { fiddle << "Example.prepend_before(:all)" }
        Example.before(:each, :behaviour_type => :special) { fiddle << "Example.before(:each, :behaviour_type => :special)" }
        Example.prepend_before(:each, :behaviour_type => :special) { fiddle << "Example.prepend_before(:each, :behaviour_type => :special)" }
        Example.before(:all, :behaviour_type => :special) { fiddle << "Example.before(:all, :behaviour_type => :special)" }
        Example.prepend_before(:all, :behaviour_type => :special) { fiddle << "Example.prepend_before(:all, :behaviour_type => :special)" }

        Example.append_before(:behaviour_type => :special) { fiddle << "Example.append_before(:each, :behaviour_type => :special)" }
        behaviour = Class.new(Example).describe("I'm not special", :behaviour_type => :special) {}
        behaviour.rspec_options = ::Spec::Runner::Options.new(StringIO.new, StringIO.new)
        behaviour.it("test") {true}
        behaviour.run
        fiddle.should == [
          'Example.prepend_before(:all)',
          'Example.before(:all)',
          'Example.prepend_before(:all, :behaviour_type => :special)',
          'Example.before(:all, :behaviour_type => :special)',
          'Example.prepend_before(:each, :behaviour_type => :special)',
          'Example.before(:each, :behaviour_type => :special)',
          'Example.append_before(:each, :behaviour_type => :special)',
        ]
      end

      it "before callbacks are ordered from global to local" do
        fiddle = []
        Example.prepend_before(:all) { fiddle << "Example.prepend_before(:all)" }
        Example.before(:all) { fiddle << "Example.before(:all)" }
        @behaviour.prepend_before(:all) { fiddle << "prepend_before(:all)" }
        @behaviour.before(:all) { fiddle << "before(:all)" }
        @behaviour.prepend_before(:each) { fiddle << "prepend_before(:each)" }
        @behaviour.before(:each) { fiddle << "before(:each)" }
        @behaviour.it("test") {true}
        @behaviour.run
        fiddle.should == [
          'Example.prepend_before(:all)',
          'Example.before(:all)',
          'prepend_before(:all)',
          'before(:all)',
          'prepend_before(:each)',
          'before(:each)'
        ]
      end

      it "after callbacks are ordered from local to global" do
        @reporter.should_receive(:add_behaviour).with any_args()
        @reporter.should_receive(:example_finished).with any_args()

        fiddle = []
        @behaviour.after(:each) { fiddle << "after(:each)" }
        @behaviour.append_after(:each) { fiddle << "append_after(:each)" }
        @behaviour.after(:all) { fiddle << "after(:all)" }
        @behaviour.append_after(:all) { fiddle << "append_after(:all)" }
        Example.after(:all) { fiddle << "Example.after(:all)" }
        Example.append_after(:all) { fiddle << "Example.append_after(:all)" }
        @behaviour.it("test") {true}
        @behaviour.run
        fiddle.should == [
          'after(:each)',
          'append_after(:each)',
          'after(:all)',
          'append_after(:all)',
          'Example.after(:all)',
          'Example.append_after(:all)'
        ]
      end

      it "should have accessible instance methods from included module" do
        @reporter.should_receive(:add_behaviour).with any_args()
        @reporter.should_receive(:example_finished).with any_args()

        mod1_method_called = false
        mod1 = Module.new do
          define_method :mod1_method do
            mod1_method_called = true
          end
        end

        mod2_method_called = false
        mod2 = Module.new do
          define_method :mod2_method do
            mod2_method_called = true
          end
        end

        @behaviour.include mod1, mod2

        @behaviour.it("test") do
          mod1_method
          mod2_method
        end
        @behaviour.run
        mod1_method_called.should be_true
        mod2_method_called.should be_true
      end

      it "should include targetted modules included using configuration" do
        $included_modules = []

        mod1 = Module.new do
          class << self
            def included(mod)
              $included_modules << self
            end
          end
        end

        mod2 = Module.new do
          class << self
            def included(mod)
              $included_modules << self
            end
          end
        end

        mod3 = Module.new do
          class << self
            def included(mod)
              $included_modules << self
            end
          end
        end

        begin
          Spec::Runner.configuration.include(mod1, mod2)
          Spec::Runner.configuration.include(mod3, :behaviour_type => :cat)

          behaviour = Class.new(Example).describe("I'm special", :behaviour_type => :dog) do
            it "does nothing"
          end
          behaviour.rspec_options = ::Spec::Runner::Options.new(StringIO.new, StringIO.new)
          behaviour.run

          $included_modules.should include(mod1)
          $included_modules.should include(mod2)
          $included_modules.should_not include(mod3)
        ensure
          Spec::Runner.configuration.exclude(mod1, mod2, mod3)
        end
      end

      it "should include any predicate_matchers included using configuration" do
        $included_predicate_matcher_found = false
        Spec::Runner.configuration.predicate_matchers[:do_something] = :does_something?
        behaviour = Class.new(Example).describe('example') do
          it "should respond to do_something" do
            $included_predicate_matcher_found = respond_to?(:do_something)
          end
        end
        behaviour.rspec_options = ::Spec::Runner::Options.new(StringIO.new, StringIO.new)
        behaviour.run
        $included_predicate_matcher_found.should be(true)
      end

      it "should use a mock framework set up in config" do
        mod = Module.new do
          class << self
            def included(mod)
              $included_module = mod
            end
          end
        end

        begin
          $included_module = nil
          Spec::Runner.configuration.mock_with mod

          behaviour = Class.new(Example).describe('example') do
            it "does nothing"
          end
          behaviour.rspec_options = ::Spec::Runner::Options.new(StringIO.new, StringIO.new)
          behaviour.run

          $included_module.should_not be_nil
        ensure
          Spec::Runner.configuration.mock_with :rspec
        end
      end
    end

    describe "Example", ".remove_after" do
      it_should_behave_like "Spec::DSL::Example"

      it "should unregister a given after(:each) block" do
        after_all_ran = false
        @behaviour.it("example") {}
        proc = Proc.new { after_all_ran = true }
        Example.after(:each, &proc)
        @behaviour.run
        after_all_ran.should be_true

        after_all_ran = false
        Example.remove_after(:each, &proc)
        @behaviour.run
        after_all_ran.should be_false
      end
    end

    describe "Example", ".include" do
      it_should_behave_like "Spec::DSL::Example"

      it "should have accessible class methods from included module" do
        mod1_method_called = false
        mod1 = Module.new do
          class_methods = Module.new do
            define_method :mod1_method do
              mod1_method_called = true
            end
          end

          metaclass.class_eval do
            define_method(:included) do |receiver|
              receiver.extend class_methods
            end
          end
        end

        mod2_method_called = false
        mod2 = Module.new do
          class_methods = Module.new do
            define_method :mod2_method do
              mod2_method_called = true
            end
          end

          metaclass.class_eval do
            define_method(:included) do |receiver|
              receiver.extend class_methods
            end
          end
        end

        @behaviour.include mod1, mod2

        @behaviour.mod1_method
        @behaviour.mod2_method
        mod1_method_called.should be_true
        mod2_method_called.should be_true
      end
    end

    describe "Example", ".number_of_examples" do
      it_should_behave_like "Spec::DSL::Example"

      it "should count number of specs" do
        @behaviour.example_definitions.clear
        @behaviour.it("one") {}
        @behaviour.it("two") {}
        @behaviour.it("three") {}
        @behaviour.it("four") {}
        @behaviour.number_of_examples.should == 4
      end
    end

    describe "Example", ".matches?" do
      it_should_behave_like "Spec::DSL::Example"

      it "should not match anything when there are no example_definitions" do
        @behaviour.should_not be_matches(['context'])
      end

      it "should match when one of the example_definitions match" do
        example = mock('my example')
        example.should_receive(:matches?).and_return(true)
        @behaviour.stub!(:example_definitions).and_return([example])
        @behaviour.should be_matches(['jalla'])
      end
    end

    describe "Example", ".class_eval" do
      it_should_behave_like "Spec::DSL::Example"

      it "should allow constants to be defined" do
        behaviour = Class.new(Example).describe('example') do
          FOO = 1
          it "should reference FOO" do
            FOO.should == 1
          end
        end
        behaviour.rspec_options = ::Spec::Runner::Options.new(StringIO.new, StringIO.new)
        behaviour.run
        Object.const_defined?(:FOO).should == false
      end

      it "should understand module scoping" do
        pending "Example.new needs to create a class that is evaled"
        module Foo
          module Bar
            def self.loaded?
              true
            end
          end
        end

        Example.new('example') do
          include Foo
          it "should allow module scoping" do
            Bar.should be_loaded
          end
        end.run
        @reporter.instance_variable_get(:@failures).should == []
        @reporter.dump.should == 0
      end

      it "should allow class variables to be defined" do
        pending "class_eval cannot be used. Only the class definition can be used. This may not be possible."
        Example.new('example') do
          @@foo = 1
          it "should reference @@foo" do
            @@foo.should == 1
          end
        end.run

        Example.new('example2') do
          it "should not have access to other class variables" do
            proc do
              @@foo
            end.should raise_error
          end
        end.run
        @reporter.dump.should == 0
      end
    end

    describe Example, '.run functional example' do
      def count
        @count ||= 0
        @count = @count + 1
        @count
      end

      before(:all) do
        count.should == 1
      end

      before(:all) do
        count.should == 2
      end

      before(:each) do
        count.should == 3
      end

      before(:each) do
        count.should == 4
      end

      it "should run before(:all), before(:each), example, after(:each), after(:all) in order" do
        count.should == 5
      end

      after(:each) do
        count.should == 7
      end

      after(:each) do
        count.should == 6
      end

      after(:all) do
        count.should == 9
      end

      after(:all) do
        count.should == 8
      end
    end

    describe Example, "#initialize" do
      the_behaviour = self
      it "should have copy of behaviour" do
        the_behaviour.superclass.should == Example
      end
    end

    describe Example, "#pending" do
      it "should support pending" do
        lambda {
          pending("something")
        }.should raise_error(Spec::DSL::ExamplePendingError, "something")
      end

      it "should raise a Pending error when its block fails" do
        block_ran = false
        lambda {
          pending("something") do
            block_ran = true
            raise "something wrong with my example"
          end
        }.should raise_error(Spec::DSL::ExamplePendingError, "something")
        block_ran.should == true
      end

      it "should raise Spec::DSL::PendingFixedError when its block does not fail" do
        block_ran = false
        lambda {
          pending("something") do
            block_ran = true
          end
        }.should raise_error(Spec::DSL::PendingFixedError, "Expected pending 'something' to fail. No Error was raised.")
        block_ran.should == true
      end
    end

    describe Example, "#run" do
      it "should not run when there are no example_definitions" do
        behaviour = Class.new(Example).describe("Foobar") {}
        behaviour.example_definitions.should be_empty
        behaviour.rspec_options = ::Spec::Runner::Options.new(StringIO.new, StringIO.new)

        reporter = mock("Reporter")
        reporter.should_not_receive(:add_behaviour)
        behaviour.run
      end
    end

    class ExampleSubclass < Example
    end

    describe "Example", " subclass" do
      it "should have access to the described_type" do
        behaviour = Class.new(ExampleSubclass).describe(ExampleDefinition){}
        behaviour.send(:described_type).should == ExampleDefinition
      end

      it "should figure out its behaviour_type based on its name ()" do
        behaviour = Class.new(ExampleSubclass).describe(ExampleDefinition){}
        behaviour.send(:behaviour_type).should == :subclass
      end

      # TODO - add an example about shared behaviours
    end

    describe Enumerable do
      def each(&block)
        ["4", "2", "1"].each(&block)
      end

      it "should be included in example_definitions because it is a module" do
        map{|e| e.to_i}.should == [4,2,1]
      end
    end

    describe "An", Enumerable, "as a second argument" do
      def each(&block)
        ["4", "2", "1"].each(&block)
      end

      it "should be included in example_definitions because it is a module" do
        map{|e| e.to_i}.should == [4,2,1]
      end
    end

    describe String do
      it "should not be included in example_definitions because it is not a module" do
        lambda{self.map}.should raise_error(NoMethodError, /undefined method `map' for/)
      end
    end
  end
end
