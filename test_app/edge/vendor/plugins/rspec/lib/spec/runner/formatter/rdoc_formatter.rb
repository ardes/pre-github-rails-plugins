module Spec
  module Runner
    module Formatter
      class RdocFormatter < BaseTextFormatter
        def add_behaviour(name)
          @output.print "# #{name}\n"
        end
  
        def example_passed(name)
          @output.print "# * #{name}\n"
        end

        def example_failed(name, counter, failure)
          @output.print "# * #{name} [#{counter} - FAILED]\n"
        end
      end
    end
  end
end