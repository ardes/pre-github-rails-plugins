module Ardes
  module ResourcesController
    module Lte122
      def self.extended(base)
        base.class_eval do
          class<<self
            alias_method_chain :resources_controller_for, :lte_1_2_2
          end
        end
      end
      
      def resources_controller_for_with_lte_1_2_2(*args)
        resources_controller_for_without_lte_1_2_2(*args)
        self.resource_service_class = ::Ardes::ResourcesController::Lte122::ResourceService
      end
      
      class ResourceService < ::Ardes::ResourceService
        def new(*args)
          if @service.respond_to?(:build)
             @service.build(*args)
          else
            super(*args)
          end
        end
      end
    end
  end
end