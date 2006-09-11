module Ardes
  module Test
    module AjaxCrud
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Usage: 
        #   test_ajax_crud ControllerClass, :model_sym_singular, :fixture [, :valid => {valid data}] [, :invalid => {invalid data}] [, :params => {params for every request}]
        #
        def test_ajax_crud(controller_class, model, fixture, data = {})
          include InstanceMethods
          cattr_accessor :ajax_crud_controller_class, :ajax_crud_model, :ajax_crud_model_class,
            :ajax_crud_fixture, :ajax_crud_valid, :ajax_crud_invalid, :ajax_crud_params
          self.ajax_crud_controller_class = controller_class
          self.ajax_crud_model            = model
          self.ajax_crud_model_class      = model.to_s.classify.constantize
          self.ajax_crud_fixture          = fixture
          self.ajax_crud_valid            = data[:valid] 
          self.ajax_crud_invalid          = data[:invalid]
          self.ajax_crud_params           = data[:params] || {}
        end
      end

      module InstanceMethods
        def self.included(base)
          base.class_eval do
            alias_method_chain :setup, :ajax_crud
          end
        end
        
        def setup_with_ajax_crud
          setup_without_ajax_crud
          @controller ||= self.ajax_crud_controller_class.new
          @request    ||= ::ActionController::TestRequest.new
          @response   ||= ::ActionController::TestResponse.new
          @ajax_crud_model = send("#{self.ajax_crud_model}".pluralize, self.ajax_crud_fixture)
        end
        
        def test_ajax_crud_index
          get :index, self.ajax_crud_params
          assert_response :success
          assert_equal assigns["#{self.ajax_crud_model}".pluralize], @controller.model_list
          assert_template "ajax_crud/index.rhtml"

          assert_tag :tag => "div", :attributes => {:id => "#{@controller.public_id}_loading", :class => 'loading'}
          assert_tag :tag => "div", :attributes => {:id => "#{@controller.public_id}_flash", :class => 'flash'}
          
          assert_ajax_crud_action_link(:action => 'new')

          @controller.model_list.each do |m|
            assert_tag :tag => "div", :attributes => {:id => @controller.public_id(:id => m.id), :class => 'actions'}
            assert_tag :tag => "div", :attributes => {:id => "#{@controller.public_id(:id => m.id)}_item_main", :class => 'item_main'}
            assert_tag :tag => "div", :attributes => {:id => "#{@controller.public_id(:id => m.id)}_item_links", :class => 'item_links'}
            
            assert_ajax_crud_action_link(:id => m.id, :action => 'edit')
            assert_ajax_crud_action_link(:id => m.id, :action => 'show')
            assert_ajax_crud_action_link(:id => m.id, :action => 'destroy')
          end
        end
        
        def test_ajax_crud_show
          xhr :get, :show, self.ajax_crud_params.merge(:id => @ajax_crud_model.id)
          assert_response :success
          assert_equal @ajax_crud_model, assigns["#{self.ajax_crud_model}"]
          assert_template "ajax_crud/open"

          assert_rjs :insert_html, :top, @controller.public_id(:id => @ajax_crud_model.id)

          convert_xhr_body
          assert_tag :tag => "div", :attributes => {:id => "#{@controller.public_id(:action => 'show', :id => @ajax_crud_model.id)}", :class => 'action'}
        end
        
        def test_ajax_crud_edit
          xhr :get, :edit, self.ajax_crud_params.merge(:id => @ajax_crud_model.id)
          assert_response :success
          
          assert_template "ajax_crud/open"
          assert_equal @ajax_crud_model, assigns["#{self.ajax_crud_model}"]
          
          assert_rjs :insert_html, :top, @controller.public_id(:id => @ajax_crud_model.id)
          
          convert_xhr_body
          assert_tag :tag => "div", :attributes => {:id => "#{@controller.public_id(:action => 'edit', :id => @ajax_crud_model.id)}", :class => 'action'}
          assert_ajax_crud_action_form :id => @ajax_crud_model.id, :action => 'update', :method => 'put'
        end
        
        def test_ajax_crud_update_valid
          return unless self.ajax_crud_valid
          prev_attributes = @ajax_crud_model.attributes.dup
          
          xhr :post, :update, self.ajax_crud_params.merge(:id => @ajax_crud_model.id, self.ajax_crud_model => self.ajax_crud_valid)
          
          assert_response :success
          assert_template "ajax_crud/update"
          assert_rjs :replace_html, @controller.public_id(:id => @ajax_crud_model.id) + "_item_main"
        
          assert prev_attributes != @ajax_crud_model.reload.attributes
        end
        
        def test_ajax_crud_update_invalid
          return unless self.ajax_crud_invalid
          prev_attributes = @ajax_crud_model.attributes.dup
          
          xhr :post, :update, self.ajax_crud_params.merge(:method => 'put', :id => @ajax_crud_model.id, self.ajax_crud_model => self.ajax_crud_invalid)
          
          assert_response :success
          assert_template "ajax_crud/update"
          assert_rjs :replace_html, @controller.public_id(:action => 'edit', :id => @ajax_crud_model.id)
          
          assert prev_attributes == @ajax_crud_model.reload.attributes
          
          convert_xhr_body
          assert_tag :tag => "div", :attributes => { :class => "error" }
        end
      
        def test_ajax_crud_new
          xhr :get, :new, self.ajax_crud_params
          assert_response :success
          assert_kind_of self.ajax_crud_model_class, assigns["#{self.ajax_crud_model}"]
          assert_template "ajax_crud/open"
          
          assert_rjs :insert_html, :top, "#{@controller.public_id}_new"
          
          convert_xhr_body
          assert_tag :tag => "div", :attributes => {:id => "#{@controller.public_id(:action => 'new')}", :class => 'action'}
          assert_ajax_crud_action_form :action => 'create', :method => 'post'
        end
        
        def test_ajax_crud_create_valid
          return unless self.ajax_crud_valid
          
          xhr :post, :create, self.ajax_crud_params.merge(self.ajax_crud_model => self.ajax_crud_valid)
          
          assert_response :success
          assert_template "ajax_crud/create"
          assert_rjs :insert_html, :before, "#{@controller.public_id}_list_end"
        
          assert_kind_of self.ajax_crud_model_class, assigns["#{self.ajax_crud_model}"]
          assert false == assigns["#{self.ajax_crud_model}"].new_record?
        end
        
        def test_ajax_crud_create_invalid
          return unless self.ajax_crud_invalid
          
          xhr :post, :create, self.ajax_crud_params.merge(self.ajax_crud_model => self.ajax_crud_invalid)
          
          assert_response :success
          assert_template "ajax_crud/create"
          assert_rjs :replace_html, "#{@controller.public_id}_new"

          assert_kind_of self.ajax_crud_model_class, assigns["#{self.ajax_crud_model}"]
          assert true == assigns["#{self.ajax_crud_model}"].new_record?
        end
        
        def test_ajax_crud_destroy
          # first init the @controller with the current params
          get :index, self.ajax_crud_params
          count_before_destroy = @controller.model_list.size 
          
          @controller = self.ajax_crud_controller_class.new
          xhr :get, :destroy, self.ajax_crud_params.merge(:id => @ajax_crud_model.id)
          assert_response :success
          assert_template "ajax_crud/destroy"
          assert_rjs :remove, "#{@controller.public_id(:id => @ajax_crud_model.id)}_item"
          
          assert_equal count_before_destroy - 1, @controller.model_list(reload = true).size
        end
        
        def test_ajax_crud_destroy_last_item
          # first init the @controller with the current params, and remove all but the first model
          get :index, self.ajax_crud_params
          (1..@controller.model_list.size-1).each { |i| @controller.model_list[i].destroy }

          if to_destroy = @controller.model_list[0]
            @controller = self.ajax_crud_controller_class.new
            xhr :get, :destroy, self.ajax_crud_params.merge(:id => to_destroy.id)
            assert_response :success
            assert_template "ajax_crud/destroy"
            assert_rjs :remove, "#{@controller.public_id}_#{to_destroy.id}_item"
            assert_rjs :insert_html, :top, "#{@controller.public_id}_list", /list_empty/
            assert_equal 0, @controller.model_list(reload = true).size
          end
        end
        
        def test_ajax_crud_create_first_item
          return unless self.ajax_crud_valid
          
          self.ajax_crud_model_class.destroy_all
          
          xhr :post, :create, self.ajax_crud_params.merge(self.ajax_crud_model => self.ajax_crud_valid)
          
          assert_response :success
          assert_template "ajax_crud/create"
          assert_rjs :insert_html, :before, "#{@controller.public_id}_list_end"
          assert_rjs :remove, "#{@controller.public_id}_list_empty"
        end
          
      private
        def assert_ajax_crud_action_link(options = {})
          assert_tag :tag => 'a', :attributes => {:onclick => /#{options[:action]}/}
        end

        def assert_ajax_crud_action_form(options = {})
          exp = Regexp.new('<form.*action.*=.*' + Regexp.escape(url_for({:controller => @controller.controller_name}.merge(options))))
          assert remove_spurious_amp(@response.body) =~ exp
        end

        def convert_xhr_body
          @response.body.gsub!('\"', '"')
        end
        
        def remove_spurious_amp(text)
          text.gsub(/\&amp;(amp;)*/, '&amp;')
        end
      end
    end
  end
end

Test::Unit::TestCase.class_eval { include Ardes::Test::AjaxCrud }