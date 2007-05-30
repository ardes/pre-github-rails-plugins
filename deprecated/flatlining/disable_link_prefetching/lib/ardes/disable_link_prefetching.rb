#
# Common technique widely available on the web, included here for our own convenience
#
# Usage
#   class ApplicationController < ActionController::Base
#     before_filter disable_link_prefetching
#   end
#
module Ardes
  module DisableLinkPrefetching
    def self.included(controller)
      controller.class_eval do
        include InstanceMethods
        before_filter :disable_link_prefetching
      end
    end
    
    module InstanceMethods
    private
      def disable_link_prefetching
        if request.env["HTTP_X_MOZ"] == "prefetch" 
          logger.debug "prefetch detected: sending 403 Forbidden" 
          render_nothing "403 Forbidden" 
          return false
        end
      end
    end
  end
end