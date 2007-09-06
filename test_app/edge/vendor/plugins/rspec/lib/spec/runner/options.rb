module Spec
  module Runner
    class Options
      BUILT_IN_FORMATTERS = {
        'specdoc'  => Formatter::SpecdocFormatter,
        's'        => Formatter::SpecdocFormatter,
        'html'     => Formatter::HtmlFormatter,
        'h'        => Formatter::HtmlFormatter,
        'rdoc'     => Formatter::RdocFormatter,
        'r'        => Formatter::RdocFormatter,
        'progress' => Formatter::ProgressBarFormatter,
        'p'        => Formatter::ProgressBarFormatter,
        'failing_examples' => Formatter::FailingExamplesFormatter,
        'e'        => Formatter::FailingExamplesFormatter,
        'failing_behaviours' => Formatter::FailingBehavioursFormatter,
        'b'        => Formatter::FailingBehavioursFormatter
      }
      
      attr_accessor(
        :backtrace_tweaker,
        :context_lines,
        :diff_format,
        :dry_run,
        :examples,
        :failure_file,
        :formatters,
        :generate,
        :heckle_runner,
        :line_number,
        :loadby,
        :reporter,
        :reverse,
        :timeout,
        :verbose,
        :runner_arg,
        :behaviour_runner
      )
      attr_reader :colour, :differ_class

      def initialize(error_stream, output_stream)
        @error_stream = error_stream
        @output_stream = output_stream
        @backtrace_tweaker = QuietBacktraceTweaker.new
        @examples = []
        @formatters = []
        @colour = false
        @dry_run = false
        @reporter = Reporter.new(self)
        @context_lines = 3
        @diff_format  = :unified
      end
      
      def colour=(colour)
        @colour = colour
        begin; \
          require 'Win32/Console/ANSI' if @colour && PLATFORM =~ /win32/; \
        rescue LoadError ; \
          raise "You must gem install win32console to use colour on Windows" ; \
        end
      end

      def create_behaviour_runner
        return nil if @generate
        if @runner_arg
          klass_name, arg = split_at_colon(@runner_arg)
          runner_type = load_class(klass_name, 'behaviour runner', '--runner')
          @behaviour_runner = runner_type.new(self, arg)
        else
          @behaviour_runner = BehaviourRunner.new(self)
        end
      end

      def differ_class=(klass)
        return unless klass
        @differ_class = klass
        Spec::Expectations.differ = self.differ_class.new(self)
      end

      def parse_diff(format)
        case format
        when :context, 'context', 'c'
          @diff_format  = :context
          default_differ
        when :unified, 'unified', 'u', '', nil
          @diff_format  = :unified
          default_differ
        else
          @diff_format  = :custom
          self.differ_class = load_class(format, 'differ', '--diff')
        end
      end

      def parse_example(example)
        if(File.file?(example))
          @examples = File.open(example).read.split("\n")
        else
          @examples = [example]
        end
      end

      def parse_format(format_arg)
        format, where = split_at_colon(format_arg)
        # This funky regexp checks whether we have a FILE_NAME or not
        if where.nil?
          raise "When using several --format options only one of them can be without a file" if @out_used
          where = @output_stream
          @out_used = true
        end

        formatter_type = BUILT_IN_FORMATTERS[format] || load_class(format, 'formatter', '--format')
        create_formatter(formatter_type, where)
      end

      def create_formatter(formatter_type, where=@output_stream)
        formatter = formatter_type.new(self, where)
        @formatters << formatter
        formatter
      end

      def parse_require(req)
        req.split(",").each{|file| require file}
      end

      def parse_heckle(heckle)
        heckle_require = [/mswin/, /java/].detect{|p| p =~ RUBY_PLATFORM} ? 'spec/runner/heckle_runner_unsupported' : 'spec/runner/heckle_runner'
        require heckle_require
        @heckle_runner = HeckleRunner.new(heckle)
      end

      def parse_generate_options(options_file, args_copy, out_stream)
        # Remove the --generate-options option and the argument before writing to file
        index = args_copy.index("-G") || args_copy.index("--generate-options")
        args_copy.delete_at(index)
        args_copy.delete_at(index)
        File.open(options_file, 'w') do |io|
          io.puts args_copy.join("\n")
        end
        out_stream.puts "\nOptions written to #{options_file}. You can now use these options with:"
        out_stream.puts "spec --options #{options_file}"
        @generate = true
      end

      def split_at_colon(s)
        if s =~ /([a-zA-Z_]+(?:::[a-zA-Z_]+)*):?(.*)/
          arg = $2 == "" ? nil : $2
          [$1, arg]
        else
          raise "Couldn't parse #{s.inspect}"
        end
      end
      
      def load_class(name, kind, option)
        if name =~ /\A(?:::)?([A-Z]\w*(?:::[A-Z]\w*)*)\z/
          arg = $2 == "" ? nil : $2
          [$1, arg]
        else
          m = "#{name.inspect} is not a valid class name"
          @error_stream.puts m
          raise m
        end
        begin
          eval(name, binding, __FILE__, __LINE__)
        rescue NameError => e
          @error_stream.puts "Couldn't find #{kind} class #{name}"
          @error_stream.puts "Make sure the --require option is specified *before* #{option}"
          if $_spec_spec ; raise e ; else exit(1) ; end
        end
      end

      protected
      def default_differ
        require 'spec/expectations/differs/default'
        self.differ_class = Spec::Expectations::Differs::Default
      end      
    end
  end
end
