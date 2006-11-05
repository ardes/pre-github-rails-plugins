module Ardes#:nodoc:
  module Validations#:nodoc:
    module ValidatesPart
      def self.included(base)
        base.class_eval { extend ClassMethods }
      end
      
      module ClassMethods
        #
        # Validates a model part (an aggregation, or association, or anything that is validatiable).
        # Any errors are merged into the containing model's errors.  The way this is done can be specified with
        # the following options:
        #
        # * <tt>:merge_errors</tt>: (default false) instead of adding errors to an attribute, merge them into the main model.
        #
        def validates_part(*attr_names)
          configuration = {}
          configuration.update(attr_names.pop) if attr_names.last.is_a?(Hash)
          
          merge_errors = configuration.delete(:merge_errors)
          
          validates_each(*attr_names.push(configuration)) do |record, attr_name, value|
            value = value.dup if value.frozen?
            if value && !value.valid?
              value.errors.each do |part_attr_name, msg|
                unless merge_errors
                  msg = "- #{part_attr_name.to_s.humanize.downcase} #{msg}"
                  part_attr_name = attr_name
                end
                record.errors.add(part_attr_name, msg)
              end
            end
          end
        end
      end
    end
  end
end