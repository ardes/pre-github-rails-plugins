require 'timeout'

module Spec
  module DSL
    class ExampleDefinition
      # The global sequence number of this example
      attr_accessor :number

      def initialize(description, options={}, &example_block)
        @from = caller(0)[3]
        @options = options
        @example_block = example_block
        @description = description
        @description_generated_proc = lambda { |desc| @generated_description = desc }
      end

      def run(reporter, before_each_block, after_each_block, dry_run, example, timeout=nil)
        @dry_run = dry_run
        reporter.example_started(self)
        return reporter.example_finished(self) if dry_run

        errors = []
        location = nil
        Timeout.timeout(timeout) do
          before_each_ok = before_example(example, errors, &before_each_block)
          example_ok = run_example(example, errors) if before_each_ok
          after_each_ok = after_example(example, errors, &after_each_block)
          location = failure_location(before_each_ok, example_ok, after_each_ok)
        end

        ExampleShouldRaiseHandler.new(@from, @options).handle(errors)
        reporter.example_finished(self, errors.first, location, pending?) if reporter
      end

      def matches?(matcher, specified_examples)
        matcher.example_description = description
        matcher.matches?(specified_examples)
      end

      def description
        @description == :__generate_description ? generated_description : @description
      end

      def to_s
        description
      end

      def pending?
        @example_block.nil?
      end

    private

      def generated_description
        return @generated_description if @generated_description
        if @dry_run
          "NO NAME (Because of --dry-run)"
        else
          if @failed
            "NO NAME (Because of Error raised in matcher)"
          else
            "NO NAME (Because there were no expectations)"
          end
        end
      end

      def before_example(example, errors, &behaviour_before_block)
        setup_mocks(example)
        Spec::Matchers.description_generated(@description_generated_proc)

        example.instance_eval(&behaviour_before_block) if behaviour_before_block
        return errors.empty?
      rescue Exception => e
        @failed = true
        errors << e
        return false
      end

      def run_example(example, errors)
        example.instance_eval(&@example_block) if @example_block
        return true
      rescue Exception => e
        @failed = true
        errors << e
        return false
      end

      def after_example(example, errors, &behaviour_after_each)
        example.instance_eval(&behaviour_after_each) if behaviour_after_each

        begin
          verify_mocks(example)
        ensure
          teardown_mocks(example)
        end

        Spec::Matchers.unregister_description_generated(@description_generated_proc)

        return errors.empty?
      rescue Exception => e
        @failed = true
        errors << e
        return false
      end

      def setup_mocks(example)
        if example.respond_to?(:setup_mocks_for_rspec)
          example.setup_mocks_for_rspec
        end
      end

      def verify_mocks(example)
        if example.respond_to?(:verify_mocks_for_rspec)
          example.verify_mocks_for_rspec
        end
      end

      def teardown_mocks(example)
        if example.respond_to?(:teardown_mocks_for_rspec)
          example.teardown_mocks_for_rspec
        end
      end

      def failure_location(before_each_ok, example_ok, after_each_ok)
        return 'before(:each)' unless before_each_ok
        return description unless example_ok
        return 'after(:each)' unless after_each_ok
      end
    end
  end
end
