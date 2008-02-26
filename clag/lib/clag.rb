# Clag is the awesome edible glue that Australian kids know and love
#
# Inspired from http://replacefixtures.rubyforge.org/
#
# Usage: stick clag.rb in a load path path somewhere (like lib/)
#
# Next, in spec_helper, or somewhere like that, reopen, or make a new class
# descended from Clag, and add tableized method names for your model attributes
#
# Say:
#
# class MyClag < Clag
#
#   #n if method sig has no options, then any extra ones are merged with the result
#   def user
#     { a hash is returned }
#   end
#
#   # if method sig has options, then it's assumed you will merge them here
#   def area(options = {})
#     { default hash }.merge(options)
#   end
# end
#
# Then do MyClag.create_user, or MyClag.new_user, or MyClag.user_attributes
#
# You can make of Clag methods like
#
#   random:     returns a random string
#
#   unique_for: guarantee a unique result when using a random value
#
#     unique_for(:user_email) { "#{random}@email.com" }
#
#
# Advantages of Clag :-
#
# * it's one tiny ruby file
# * you can group data together by scenarios by making a new clag class
# * all of the features of fixture replacement type thingies
#
class Clag
  module Dispatcher
    def respond_to?(method)
      super(method) || /^(create|new)_(\w+)(!?)$/.match(method.to_s) || method =~ /^(\w+)_attributes$/
    end
    
    def method_missing(method, *args, &block)
      if match = /^(create|new)_(\w+)(!?)$/.match(method.to_s)
        dispatch(match[2], match[1] + match[3], args[0])
      elsif method =~ /^(\w+)_attributes$/
        new.send(method)
      else
        super(method, *args, &block)
      end
    end
    
    def dispatch(model, method, options)
      klass = model.camelize.constantize
      clag = self.is_a?(Class) ? self : self.class
      attrs = clag.new.method(model)
      if attrs.arity == 0
        klass.send method, attrs.call.merge(options || {})
      else
        klass.send method, attrs.call(options || {})
      end
    end
  end
  
  include Dispatcher
  
  class << self
    include Dispatcher
    
    def unique?(key, value)
      @@unique ||= {}
      @@unique[key] ||= {}
      @@unique[key][value] ? false : @@unique[key][value] = true
    end
  end
  
  def random(length=10)
    chars = ("a".."z").to_a
    (1..length).to_a.inject("") {|m, _| m << chars[rand(chars.size-1)]}
  end
  
  def unique_for(key, &block)
    100.times do
      candidate = block.call
      return candidate if self.class.unique?(key, candidate)
    end
    raise "Pass a block that changes to unique_for"
  end
end