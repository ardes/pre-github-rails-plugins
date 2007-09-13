module Kernel
  # Creates and registers an instance of a Spec::DSL::Example (or a subclass).
  # The instantiated behaviour class depends on the directory of the file
  # calling this method. For example, Spec::Rails will use different
  # classes for specs living in <tt>spec/models</tt>, <tt>spec/helpers</tt>, 
  # <tt>spec/views</tt> and <tt>spec/controllers</tt>.
  #
  # It is also possible to override autodiscovery of the behaviour class 
  # with an options Hash as the last argument:
  #
  #   describe "name", :behaviour_type => :something_special do ...
  #
  # The reason for using different behaviour classes is to have
  # different matcher methods available from within the <tt>describe</tt>
  # block.
  #
  # See Spec::DSL::ExampleFactory#add_example_class for details about 
  # how to register special Spec::DSL::Example implementations.
  #
  def describe(*args, &block)
    raise ArgumentError if args.empty?
    raise ArgumentError unless block
    args << {} unless Hash === args.last
    args.last[:spec_path] = caller(0)[1]
    register_behaviour(Spec::DSL::ExampleFactory.create(*args, &block))
  end
  alias :context :describe

  def respond_to(*names)
    Spec::Matchers::RespondTo.new(*names)
  end
  
private

  def register_behaviour(behaviour)
    if behaviour.shared?
      Spec::DSL::SharedBehaviour.add_shared_behaviour(behaviour)
    else
      behaviour_runner.add_behaviour(behaviour)
    end
  end

  def behaviour_runner
    # TODO: Figure out a better way to get this considered "covered" and keep this statement on multiple lines 
    unless $behaviour_runner; \
      options = ::Spec::Runner::OptionParser.parse(ARGV.dup, STDERR, STDOUT, false); \
      $behaviour_runner = options.create_behaviour_runner;
    end
    $behaviour_runner
  end
end
