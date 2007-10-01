require 'optparse'
require 'stringio'

module Spec
  module Runner
    class OptionParser < ::OptionParser
      class << self
        def parse(args, err, out)
          parser = new(err, out)
          parser.parse(args)
          parser.options
        end
      end

      attr_reader :options

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

      OPTIONS = {
        :diff =>    ["-D", "--diff [FORMAT]", "Show diff of objects that are expected to be equal when they are not",
                                             "Builtin formats: unified|u|context|c",
                                             "You can also specify a custom differ class",
                                             "(in which case you should also specify --require)"],
        :colour =>  ["-c", "--colour", "--color", "Show coloured (red/green) output"],
        :example => ["-e", "--example [NAME|FILE_NAME]",  "Execute example(s) with matching name(s). If the argument is",
                                                          "the path to an existing file (typically generated by a previous",
                                                          "run using --format failing_examples:file.txt), then the examples",
                                                          "on each line of thatfile will be executed. If the file is empty,",
                                                          "all examples will be run (as if --example was not specified).",
                                                          " ",
                                                          "If the argument is not an existing file, then it is treated as",
                                                          "an example name directly, causing RSpec to run just the example",
                                                          "matching that name"],
        :specification => ["-s", "--specification [NAME]", "DEPRECATED - use -e instead", "(This will be removed when autotest works with -e)"],
        :line => ["-l", "--line LINE_NUMBER", Integer, "Execute behaviout or specification at given line.",
                                                       "(does not work for dynamically generated specs)"],
        :format => ["-f", "--format FORMAT[:WHERE]",  "Specifies what format to use for output. Specify WHERE to tell",
                                                    "the formatter where to write the output. All built-in formats",
                                                    "expect WHERE to be a file name, and will write to STDOUT if it's",
                                                    "not specified. The --format option may be specified several times",
                                                    "if you want several outputs",
                                                    " ",
                                                    "Builtin formats: ",
                                                    "progress|p           : Text progress",
                                                    "specdoc|s            : Example doc as text",
                                                    "rdoc|r               : Example doc as RDoc",
                                                    "html|h               : A nice HTML report",
                                                    "failing_examples|e   : Write all failing examples - input for --example",
                                                    "failing_behaviours|b : Write all failing behaviours - input for --example",
                                                    " ",
                                                    "FORMAT can also be the name of a custom formatter class",
                                                    "(in which case you should also specify --require to load it)"],
        :require => ["-r", "--require FILE", "Require FILE before running specs",
                                          "Useful for loading custom formatters or other extensions.",
                                          "If this option is used it must come before the others"],
        :backtrace => ["-b", "--backtrace", "Output full backtrace"],
        :loadby => ["-L", "--loadby STRATEGY", "Specify the strategy by which spec files should be loaded.",
                                              "STRATEGY can currently only be 'mtime' (File modification time)",
                                              "By default, spec files are loaded in alphabetical order if --loadby",
                                              "is not specified."],
        :reverse => ["-R", "--reverse", "Run examples in reverse order"],
        :timeout => ["-t", "--timeout FLOAT", "Interrupt and fail each example that doesn't complete in the",
                                              "specified time"],
        :heckle => ["-H", "--heckle CODE", "If all examples pass, this will mutate the classes and methods",
                                           "identified by CODE little by little and run all the examples again",
                                           "for each mutation. The intent is that for each mutation, at least",
                                           "one example *should* fail, and RSpec will tell you if this is not the",
                                           "case. CODE should be either Some::Module, Some::Class or",
                                           "Some::Fabulous#method}"],
        :dry_run => ["-d", "--dry-run", "Invokes formatters without executing the examples."],
        :options_file => ["-O", "--options PATH", "Read options from a file"],
        :generate_options => ["-G", "--generate-options PATH", "Generate an options file for --options"],
        :runner => ["-U", "--runner RUNNER", "Use a custom BehaviourRunner."],
        :drb => ["-X", "--drb", "Run examples via DRb. (For example against script/spec_server)"],
        :version => ["-v", "--version", "Show version"],
        :help => ["-h", "--help", "You're looking at it"]
      }

      def initialize(err, out)
        super()
        @error_stream = err
        @out_stream = out
        @options = Options.new(@error_stream, @out_stream)

        @spec_parser = SpecParser.new
        @file_factory = File

        self.banner = "Usage: spec (FILE|DIRECTORY|GLOB)+ [options]"
        self.separator ""
        on(*OPTIONS[:diff]) {|diff| @options.parse_diff(diff)}
        on(*OPTIONS[:colour]) {@options.colour = true}
        on(*OPTIONS[:example]) {|example| @options.parse_example(example)}
        on(*OPTIONS[:specification]) {|example| @options.parse_example(example)}
        on(*OPTIONS[:line]) {|line_number| @options.line_number = line_number.to_i}
        on(*OPTIONS[:format]) {|format| @options.parse_format(format)}
        on(*OPTIONS[:require]) {|req| @options.parse_require(req)}
        on(*OPTIONS[:backtrace]) {@options.backtrace_tweaker = NoisyBacktraceTweaker.new}
        on(*OPTIONS[:loadby]) {|loadby| @options.loadby = loadby}
        on(*OPTIONS[:reverse]) {@options.reverse = true}
        on(*OPTIONS[:timeout]) {|timeout| @options.timeout = timeout.to_f}
        on(*OPTIONS[:heckle]) {|heckle| @options.parse_heckle(heckle)}
        on(*OPTIONS[:dry_run]) {@options.dry_run = true}
        on(*OPTIONS[:options_file]) {|options_file| parse_options_file(options_file)}
        on(*OPTIONS[:generate_options]) do |options_file|
        end
        on(*OPTIONS[:runner]) do |runner|
          @options.runner_arg = runner
        end
        on(*OPTIONS[:drb]) {}
        on(*OPTIONS[:version]) {parse_version}
        self.on_tail(*OPTIONS[:help]) {parse_help}
      end

      def order!(argv=default_argv, &blk)
        @argv = argv
        return if parse_generate_options
        return if parse_drb
        
        super(@argv) do |file|
          @options.files << file
          blk.call(file) if blk
        end

        if @options.line_number
          set_spec_from_line_number
        end

        if @options.formatters.empty?
          @options.create_formatter(Formatter::ProgressBarFormatter)
        end

        @options
      end

      protected
      def parse_options_file(options_file)
        option_file_args = IO.readlines(options_file).map {|l| l.chomp.split " "}.flatten
        @argv.push(*option_file_args)
      end

      def parse_generate_options
        # Remove the --generate-options option and the argument before writing to file
        options_file = nil
        ['-G', '--generate-options'].each do |option|
          if index = @argv.index(option)
            @argv.delete_at(index)
            options_file = @argv.delete_at(index)
          end
        end
        
        if options_file
          write_generated_options(options_file)
          return true
        else
          return false
        end
      end
      
      def write_generated_options(options_file)
        File.open(options_file, 'w') do |io|
          io.puts @argv.join("\n")
        end
        @out_stream.puts "\nOptions written to #{options_file}. You can now use these options with:"
        @out_stream.puts "spec --options #{options_file}"
        @options.generate = true
      end

      def parse_drb
        is_drb = false
        is_drb ||= @argv.delete(OPTIONS[:drb][0])
        is_drb ||= @argv.delete(OPTIONS[:drb][1])
        return is_drb ? DrbCommandLine.run(@argv, @error_stream, @out_stream) : nil
      end

      def parse_version
        @out_stream.puts ::Spec::VERSION::DESCRIPTION
        exit if stdout?
      end

      def parse_help
        @out_stream.puts self
        exit if stdout?
      end      

      def set_spec_from_line_number
        if @options.examples.empty?
          if @options.files.length == 1
            if @file_factory.file?(@options.files[0])
              source = @file_factory.open(@options.files[0])
              example = @spec_parser.spec_name_for(source, @options.line_number)
              @options.parse_example(example)
            elsif @file_factory.directory?(@options.files[0])
              @error_stream.puts "You must specify one file, not a directory when using the --line option"
              exit(1) if stderr?
            else
              @error_stream.puts "#{@options.files[0]} does not exist"
              exit(2) if stderr?
            end
          else
            @error_stream.puts "Only one file can be specified when using the --line option: #{@options.files.inspect}"
            exit(3) if stderr?
          end
        else
          @error_stream.puts "You cannot use both --line and --example"
          exit(4) if stderr?
        end
      end

      def stdout?
        @out_stream == $stdout
      end

      def stderr?
        @error_stream == $stderr
      end
    end
  end
end
