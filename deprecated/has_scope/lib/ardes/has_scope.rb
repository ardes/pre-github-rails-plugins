module Ardes#:nodoc:
  # if you do this in your model:
  #
  #   has_scope :published, :find => {:conditions => ['published = ?', true]}, :create => {:published => true}
  #
  # You get these:
  #
  #   with_published { # whatever }
  #   find_published
  #   find_published_by_title
  #   count_published
  #   sum_published(:readers)
  #   new_published
  #   destroy_all_published
  #
  # Basically, when you send a method with '_published' in it a new method will be
  # constructed with the published scope around it, and that method called.
  module HasScope
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        class_inheritable_accessor :named_scopes
      end
    end
    
    module ClassMethods
      def self.extended(base)
        class<<base
          alias_method_chain :method_missing, :has_scope
        end
      end
      
      # specify a named scope for this active record
      #
      #   has_scope :the_name, :find => {}, :create => {}
      def has_scope(name, options)
        self.named_scopes ||= {}
        self.named_scopes[name.to_sym] = options
        module_eval "def self.with_#{name}; with_scope(self.named_scopes[:#{name}]) { yield }; end"
        module_eval "def self.#{name}; with_#{name} { find(:all) }; end"
      end
      
      # NB: taking a leaf out of Rails book and not defining the corresponding
      # respond_to? for dynamic methods.  I don't think this is a great idea, but
      # it doesn't make much sense for the following:
      #   User.respond_to?(:find_by_login)            # => false (Rails default behaviour)
      #   User.respond_to?(:find_activated_by_login)  # => true
      #
      # Also, this implementation defines a new method to short circut future
      # method_missing calls
      def method_missing_with_has_scope(method, *args, &block)
        if named_scopes
          named_scopes.keys.each do |name|
            inner = method.to_s.sub("_#{name}",'')
            if inner =~ /^find(_all)_by/ || respond_to?(inner)
              module_eval "def self.#{method}(*args, &block); with_#{name} { #{inner}(*args, &block) }; end"
              return send(method, *args, &block)
            end
          end
        end
        method_missing_without_has_scope(method, *args, &block)
      end
    end
  end
end