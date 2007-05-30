module Ardes
  module TeslyReporter
    def self.plugin_name=(plugin_name)
      ::TeslyReporter::Config.user = 'cb3344820ce8'
      ::TeslyReporter::Config.app_name = "plugin: #{plugin_name} (rails: #{rails_version})"
    end
  
    # glean rails version from svn info or, failing that, Rails::VERSION
    def self.rails_version
      info = `svn info #{RAILS_ROOT}/vendor/rails`
      if info =~ /URL: http:\/\/dev\.rubyonrails\.org\/svn\/rails\/trunk/
        info =~ /Revision: (\d{1,6})/
        "r#{$1}"
      else
        require 'rails/version'
        Rails::VERSION::STRING
      end
    end
  end
end