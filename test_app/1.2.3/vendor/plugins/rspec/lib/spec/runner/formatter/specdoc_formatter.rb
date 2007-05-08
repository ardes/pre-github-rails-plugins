module Spec
  module Runner
    module Formatter
      class SpecdocFormatter < BaseTextFormatter      
        def add_behaviour(name)
          @output.puts
          @output.puts name
        end
      
        def example_failed(name, counter, failure)
          @output.puts failure.expectation_not_met? ? red("- #{name} (FAILED - #{counter})") : magenta("- #{name} (ERROR - #{counter})")
        end
      
        def example_passed(name)
          @output.print green("- #{name}\n")
        end
      end
    end
  end
end