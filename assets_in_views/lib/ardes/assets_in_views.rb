module Ardes
  module ActionController
    module AssetsInViews
      #
      # install the following route in routes.rb for maximum browser compatibility
      #
      # map.connect ':controller/asset/:format/:source.:extension', :action => 'asset'
      #
      def assets_in_views(options = {})
        include Actions
        include InstanceMethods
        helper Helper
        caches_page(:asset) unless options[:cache] == false
      end

      module Actions
        def asset
          if respond_to?(asset_method = "#{params[:format]}_asset")
            send asset_method
          else
            render_asset
          end
        end
      end
      
      module InstanceMethods
      protected
        def render_asset(content_type = "text/plain")
          render :file => "#{self.class.controller_path}/#{params[:source]}.#{params[:format]}",
            :content_type => content_type, :use_full_path => true
        end
        
        def rcss_asset
          render_asset 'text/css'
        end
        
        def r_js_asset
          render_asset 'text/javascript'
        end          
      end
    
      module Helper
        def views_stylesheet_link_tag(*sources)
          options = sources.last.is_a?(Hash) ? sources.pop : {}
          out = ''
          sources = ['stylesheet'] if sources.size == 0
        
          sources.each do |source|
            source, extension = path_and_extension(source)
            extension ||= 'css'
            options[:href] = url_for(:action => 'asset', :format => 'rcss', :source => source, :extension => extension)
            out << stylesheet_link_tag(source, options)
          end
        
          out
        end
      
        def views_javascript_include_tag(*sources)
          out = ''
          sources = ['javascript.js'] if sources.size == 0
          sources.each do |source|
            source, extension = path_and_extension(source)
            extension ||= 'js'
            out << "<script src=\"#{url_for(:action => 'asset', :format => 'r_js', :source => source, :extension => extension)}\" type=\"text/javascript\"></script>\n"
          end
          out
        end
      
      private
        def path_and_extension(path)
          path_without_extension = path.sub(/\.(\w+)$/, '')
          [ path_without_extension, $1 ]
        end
      end
    end
  end
end