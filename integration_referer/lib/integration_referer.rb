# Add HTTP_REFERER capability to integration tests
#
# Basically, within a session, each request stores it's protocol, host and path
# and that gets added to the next request's headers as HTTP_REFERER
#
# If you want to break the chain, just pass :referer => nil in the headers (or
# pass any other url to referer)
module Ardes
  module IntegrationReferer
    def self.included(base)
      [:head, :get, :put, :post, :delete].each do |verb|
        base.module_eval <<-end_eval
          def #{verb}_with_referer(path, parameters = nil, headers = nil)
            headers ||= {}
            headers[:referer] = @last_request_url unless headers.key?(:referer)
            #{verb}_without_referer(path, parameters, headers)
          ensure
            @last_request_url = request.protocol + request.host_with_port + path
          end
          alias_method_chain :#{verb}, :referer
        end_eval
      end
    end
  end
end

ActionController::Integration::Session.send :include, Ardes::IntegrationReferer