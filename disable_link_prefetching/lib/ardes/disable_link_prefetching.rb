#
# Common technique widely available on the web, included here for our own convenience
#

class ActionController::Base
private
  def disable_link_prefetching
    if request.env["HTTP_X_MOZ"] == "prefetch" 
      logger.debug "prefetch detected: sending 403 Forbidden" 
      render_nothing "403 Forbidden" 
      return false
    end
  end
end