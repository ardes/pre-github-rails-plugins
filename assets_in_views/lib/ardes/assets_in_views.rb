module Ardes #:nodoc:
  module ActionController #:nodoc:
    # Specify this in your controller if you want to serve assets (such as stylesheets and javascripts)
    # from your views directory.  Any such files are parsed as templates before serving.  This means you 
    # may add dynamicity to your css and of asset files.
    #
    # This comes set up to deal with css and js files - the template extensions are '.rcss' and '.r_js'
    #
    # NOTE: javascripts served in this way are _not_ .rjs files, they dont; contain instructions on modifying
    #       the DOM, they're just plain javascript.  To avoid confusion they end in the extension '.r_js'
    #
    # This should work out of the box with most browsers, as the 'Content-Type' header is set appropriately
    # To ensure full compatability add the following route to config/routes.rb
    #
    #   map.connect ':controller/asset/:format/:source.:extension', :action => 'asset'
    #
    # This route makes nice pretty urls for the asset action (like /foo/asset/rcss/stylesheet.css)
    #
    # == Usage
    #
    # In your controller do this
    #
    #   class MyController < ApplicationController
    #     assets_in_views
    #     ...
    #   
    # By default any assets served are cached with page caching, if you want to turn this off pass :cache => false
    #
    #     assets_in_views :cache => false
    #
    # Now a url like '/my/asset/rcss/foo.css' will look for 'foo.rcss' in the my/ views directory, parse and serve
    # that.
    # 
    # In yor views (say in a layout, you can do this) you can use the helpers provided to easily create the tags
    # required for including javascripts or linking to stylesheets 
    #
    #   views_stylesheet_link_tag 'foo'                          => link to current controller's view dir/foo.rcss
    #   views_stylesheet_link_tag 'foo', :controller => 'sheep'  => link to sheep/foo.rcss
    #   
    #   views_javascript_include_tag 'foo', 'bar', 'baz/foo'     => link to current controller's view dir
    #                                                               foo.r_js, bar.r_js and baz/foo.r_js
    # 
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
          asset_options = {:controller => options.delete(:controller)}
          sources = ['stylesheet'] if sources.size == 0
          create_views_asset_tags(sources, asset_options.merge(:format => 'rcss', :extension => 'css')) do |source, url|
            stylesheet_link_tag(source, options.merge(:href => url))
          end
        end
        
        def views_javascript_include_tag(*sources)
          options = sources.last.is_a?(Hash) ? sources.pop : {}
          sources = ['javascript'] if sources.size == 0
          create_views_asset_tags(sources, options.merge(:format => 'r_js', :extension => 'js')) do |source, url|
            "<script src=\"#{url}\" type=\"text/javascript\"></script>\n"
          end
        end

      private
        def create_views_asset_tags(sources, options, &block)
          out = ''
          url_options = {:action => 'asset', :format => options[:format]}
          url_options[:controller] = options[:controller] if options[:controller]
          sources.each do |source|
            source, extension = path_and_extension(source)
            url = url_for(url_options.merge(:source => source, :extension => extension || options[:extension]))
            out << yield(source, url)
          end
          out
        end    
        
        def path_and_extension(path)
          path_without_extension = path.sub(/\.(\w+)$/, '')
          [ path_without_extension, $1 ]
        end
      end
    end
  end
end