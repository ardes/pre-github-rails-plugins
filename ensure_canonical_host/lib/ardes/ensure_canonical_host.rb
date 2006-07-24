module Ardes
  module ActionController
    module EnsureCanonicalHost
      def ensure_canonical_host(domain, canonical = nil, protocol = 'http')
        if domain.is_a? String
          canonical ||= "www.#{domain}"
          domain = Regexp.new("#{Regexp.escape(domain)}$")
        elsif domain.is_a? Regexp
          raise ArgumentError, 'must specify 2nd argument (redirect_to host) when 1st argument is a Regexp' unless canonical
        else
          raise ArgumentError, '1st argument must be either a String or Regexp'
        end
        
        before_filter do |controller|
          if controller.request.host != canonical && controller.request.host =~ domain
            controller.instance_eval { redirect_to("#{protocol}://#{canonical}#{controller.request.request_uri}") }
            false
          end
        end
      end
    end
  end
end