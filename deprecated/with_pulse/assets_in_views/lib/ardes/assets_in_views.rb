module Ardes #:nodoc:
  module ActionController #:nodoc:
    #
    # Specify this in your controller if you want to serve assets (such as stylesheets and javascripts)
    # from your views directory.  Any such files are parsed as templates before serving.  This means you 
    # may add dynamicity to your css and of asset files.
    #
    # This comes set up to deal with css and js files - the template extensions are '.rcss' and '.r_js', but
    # you can easily add your own asset serving helpers (see Ardes::ActionController::AssetsInViews::InstanceMethods#rcss_asset)
    #
    # NOTE: javascripts served in this way are _not_ .rjs files, they dont; contain instructions on modifying
    # the DOM, they're just plain javascript.  To avoid confusion they end in the extension '.r_js'
    #
    # This should work out of the box with most browsers, as the 'Content-Type' header is set appropriately
    # To ensure full compatability add the following route to config/routes.rb
    #
    #   map.connect ':controller/asset/:format/:source.:extension', :action => 'asset', :source => /.*/
    #
    # This route makes nice pretty urls for the asset action (like '/foo/asset/rcss/stylesheet.css')
    #
    # == Usage
    #
    # In your controller do this
    #
    #   class MyController < ApplicationController
    #     assets_in_views
    #     ...
    #   
    # By default any assets served are cached with page caching, if you want to turn this off pass ':cache => false'
    #
    #     assets_in_views :cache => false
    #
    # Now a url like '/my/asset/rcss/foo.css' will look for 'foo.rcss' in the my/ views directory, parse and serve
    # that.
    # 
    # In yor views (say in a layout, you can do this) you can use the helpers provided to easily create the tags
    # required for including javascripts or linking to stylesheets 
    #
    #   views_stylesheet_link_tag 'foo'                          # => link to current controller's view dir/foo.rcss
    #   views_stylesheet_link_tag 'foo', :controller => 'sheep'  # => link to sheep/foo.rcss
    #   
    #   views_javascript_include_tag 'foo', 'bar', 'baz/foo'     # => link to current controller's view dir
    #                                                                 foo.r_js, bar.r_js and baz/foo.r_js
    #
    # To render an asset file in your views use
    #   render_asset 'filename.rcss'     # => renders asset 'filename.rcss' in current controller's view dir
    #   render_asset 'foo/filename.rcss' # => renders 'views/foo/filename.rcss'
    #
    #
    # == Routes
    #
    # If you have caching turned on for assets (the default), you may wish to install the following routes to have all
    # assets cached in one or two directories.  The following routes will keep css files in public/stylesheets and js files
    # in 'public/javascripts'
    #   map.connect 'stylesheets/:controller/:source.:extension', :action => 'asset', :source => /.*/, :format => 'rcss'
    #   map.connect 'javascripts/:controller/:source.:extension', :action => 'asset', :source => /.*/, :format => 'r_js'
    #
    module AssetsInViews
      def assets_in_views(options = {})
        include InstanceMethods
        helper Helper
        caches_page(:asset) unless options[:cache] == false
      end

      module InstanceMethods
        def asset
          if respond_to?(asset_method = "#{params[:format]}_asset")
            send asset_method
          else
            render(:nothing => true, :status => 404)
          end
        end
      
      protected
        def render_asset(content_type = "text/plain")
          render :file => "#{self.class.controller_path}/#{params[:source]}.#{params[:format]}",
            :content_type => content_type, :use_full_path => true
        end
        
        # renders an rcss asset
        def rcss_asset
          render_asset 'text/css'
        end
        
        # renders an r_js asset
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
            url.sub!('&amp;', '&') # prevent  & in &amp being substituted by stylesheet_link_tag
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
        
        def render_asset(source, options = {})
          source = "#{controller.class.controller_path}/#{source}" unless source.include?('/')
          render :file => source, :use_full_path => true
        end

      private
        def create_views_asset_tags(sources, options, &block)
          out = ''
          url_options = {:action => 'asset', :format => options[:format]}
          url_options[:controller] = options[:controller] if options[:controller]
          sources.each do |source|
            source = source.sub(/\.(\w+)$/, '')
            extension = $1
            url = url_for(url_options.merge(:source => source, :extension => extension || options[:extension]))
            out << yield(source, url)
          end
          out
        end
      end
    end
  end
end