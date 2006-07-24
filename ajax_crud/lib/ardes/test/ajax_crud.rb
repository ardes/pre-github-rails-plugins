module Ardes
  module Test
    module AjaxCrud
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Usage: 
        #   test_ajax_crud ControllerClass, :model, :fixture, [:valid => {valid data}, :invalid => {invalid data}]
        #
        def test_ajax_crud(controller_class, model, fixture, data = {})
          include InstanceMethods
          cattr_accessor :ajax_crud_controller_class, :ajax_crud_model, :ajax_crud_model_class,
            :ajax_crud_fixture, :ajax_crud_valid, :ajax_crud_invalid
          self.ajax_crud_controller_class = controller_class
          self.ajax_crud_model            = model
          self.ajax_crud_model_class      = model.to_s.classify.constantize
          self.ajax_crud_fixture          = fixture
          self.ajax_crud_valid            = data[:valid] 
          self.ajax_crud_invalid          = data[:invalid]
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
          get :index
          assert_response :success
          assert_equal assigns["#{self.ajax_crud_model}".pluralize], self.ajax_crud_model_class.find_all
          assert_template "ajax_crud/index"

          assert_ajax_crud_div(nil, nil, 'loading', :class => 'loading')
          assert_ajax_crud_div(nil, nil, 'message', :class => 'message')
          assert_ajax_crud_action_link('new', 'edit')

          @controller.model_list.each do |m|
            assert_ajax_crud_div(m.id, :class => 'actions')
            assert_ajax_crud_div(m.id, nil, 'item_main', :class => 'item_main')
            assert_ajax_crud_div(m.id, nil, 'item_links', :class => 'item_links')
            assert_ajax_crud_action_link(m.id, 'edit')
            assert_ajax_crud_action_link(m.id, 'show')
            assert_ajax_crud_action_link(m.id, 'destroy')
          end
        end
        
        def test_ajax_crud_show
          xhr :get, :show, :id => @ajax_crud_model.id
          assert_response :success
          assert_equal @ajax_crud_model, assigns["#{self.ajax_crud_model}"]
          assert_template "ajax_crud/open"

          assert_rjs :insert_html, :top, "#{self.ajax_crud_model}_#{@ajax_crud_model.id}"

          convert_xhr_body
          assert_ajax_crud_div @ajax_crud_model.id, 'show', :class => 'action'
          assert_ajax_crud_action_form @ajax_crud_model.id, 'show'
        end
        
        def test_ajax_crud_edit
          xhr :get, :edit, :id => @ajax_crud_model.id
          assert_response :success
          assert_equal @ajax_crud_model, assigns["#{self.ajax_crud_model}"]
          assert_template "ajax_crud/open"
          
          assert_rjs :insert_html, :top, "#{self.ajax_crud_model}_#{@ajax_crud_model.id}"
          
          convert_xhr_body
          assert_ajax_crud_div @ajax_crud_model.id, 'edit', :class => 'action'
          assert_ajax_crud_action_form @ajax_crud_model.id, 'edit'
        end
        
        def test_ajax_crud_edit_post_valid
          return unless self.ajax_crud_valid
          prev_attributes = @ajax_crud_model.attributes.dup
          
          xhr :post, :edit, :id => @ajax_crud_model.id, self.ajax_crud_model => self.ajax_crud_valid
          
          assert_response :success
          assert_template "ajax_crud/edit"
          assert_rjs :replace_html, "#{@controller.controller_name}_#{@ajax_crud_model.id}_item_main"
        
          assert prev_attributes == @ajax_crud_model.attributes
        end
        
        def test_ajax_crud_edit_post_invalid
          return unless self.ajax_crud_invalid
          prev_attributes = @ajax_crud_model.attributes.dup
          
          xhr :post, :edit, :id => @ajax_crud_model.id, self.ajax_crud_model => self.ajax_crud_invalid
          
          assert_response :success
          assert_template "ajax_crud/error"
          assert_rjs :replace_html, "#{@controller.controller_name}_#{@ajax_crud_model.id}_edit"
          
          assert prev_attributes == @ajax_crud_model.attributes
          
          convert_xhr_body
          assert_tag :tag => "div", :attributes => { :class => "error" }
        end
      
        def test_ajax_crud_new
          xhr :get, :edit, :id => 'new'
          assert_response :success
          assert_kind_of self.ajax_crud_model_class, assigns["#{self.ajax_crud_model}"]
          assert_template "ajax_crud/open"
          
          assert_rjs :insert_html, :top, "#{@controller.controller_name}_new"
          
          convert_xhr_body
          assert_ajax_crud_div 'new', 'edit', :class => 'action'
          assert_ajax_crud_action_form 'new', 'edit'
        end
        
        def test_ajax_crud_new_post_valid
          return unless self.ajax_crud_valid
          
          xhr :post, :edit, :id => 'new', self.ajax_crud_model => self.ajax_crud_valid
          
          assert_response :success
          assert_template "ajax_crud/edit"
          assert_rjs :insert_html, :bottom, "#{@controller.controller_name}_list"
        
          assert_kind_of self.ajax_crud_model_class, assigns["#{self.ajax_crud_model}"]
          assert false == assigns["#{self.ajax_crud_model}"].new_record?
        end
        
        def test_ajax_crud_new_post_invalid
          return unless self.ajax_crud_invalid
          
          xhr :post, :edit, :id => 'new', self.ajax_crud_model => self.ajax_crud_invalid
          
          assert_response :success
          assert_template "ajax_crud/error"
          assert_rjs :replace_html, "#{@controller.controller_name}_new_edit"

          assert_kind_of self.ajax_crud_model_class, assigns["#{self.ajax_crud_model}"]
          assert true == assigns["#{self.ajax_crud_model}"].new_record?
        end

      private
        # id, action, suffix, attrs..
        def assert_ajax_crud_div(*args)
          attributes = args.last.is_a?(Hash) ? args.pop : {}
          attributes[:id] = ajax_crud_public_id(*args)
          assert_tag :tag => "div", :attributes => attributes
        end

        def assert_ajax_crud_action_link(id, action)
          assert_tag :tag => 'a', :attributes => {:id => ajax_crud_public_id(id, action, 'open')}
          assert_tag :tag => 'a', :attributes => {:id => ajax_crud_public_id(id, action, 'goto')}
        end

        def assert_ajax_crud_action_form(id, action)
          assert_tag :tag => 'form', :attributes => {:action => url_for(@controller.internal_url(
            :controller => @controller.controller_name, :action => action, :id => id))}
        end

        # [id [, action [, suffix]]]
        def ajax_crud_public_id(*args)
          id     = args.shift
          action = args.shift
          suffix = args.shift

          ajax_crud_public_id = @controller.public_id(:id => id, :action => action)
          ajax_crud_public_id += "_#{suffix}" if suffix

          ajax_crud_public_id
        end

        def convert_xhr_body
          @response.body.gsub!('\"', '"')
        end
      end
    end
  end
end

Test::Unit::TestCase.class_eval { include Ardes::Test::AjaxCrud }