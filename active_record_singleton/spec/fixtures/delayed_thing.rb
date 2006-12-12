require File.join(File.dirname(__FILE__), 'thing')

# add a delay after the singleton attributes are read.  This will expose any
# concurrency issues as concurrrent access will all perform the read before an
# update or insert is performed
class DelayedThing < Thing
  def read_singleton_attributes_with_delay
    read_singleton_attributes_without_delay
  ensure
    sleep 0.2
  end
  alias_method_chain :read_singleton_attributes, :delay
end
