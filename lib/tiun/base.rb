require 'active_support'

module Tiun::Base
   extend ActiveSupport::Concern

   included do
      #attr_accessor :params
      #define_callbacks :subscribe
      # include Kaminari::ConfigurationMethods
      #class_attribute :_helpers
      #self._helpers = Module.new
      #include ActiveSupport::Configurable
      #config_accessor :co
#      helper_method :cookies if defined?(helper_method)
#      around_perform do |job, block, _|
#         I18n.with_locale(I18n.locale.to_s, &block)
#      include Pundit

#      before_action :authenticate_user!
#      before_action :set_tokens, only: %i(index)
#      before_action :set_page, only: %i(index)
#      before_action :set_locales
      before_action :new_object, only: %i(create)
#      before_action :fetch_object, only: %i(show update destroy)
#      before_action :fetch_objects, only: %i(index)
#      before_action :authorize!

      rescue_from ActiveRecord::RecordNotUnique,
                  ActiveRecord::RecordInvalid,
                  ActiveRecord::RecordNotSaved,
                  ActiveRecord::RecordNotFound, with: :unprocessable_entity

#      has_scope :with_token, only: %i(index all)
#      has_scope :with_tokens, only: %i(index), type: :array

   end

   # GET /<objects>/
   def index
      # binding.pry
      respond_to do |format|
         format.json { render json: { list: paged_objects.jsonize(context), page: page, per: per, total: total }}
#         format.json { render :index, json: objects, locales: locales,
#                                      serializer: objects_serializer,
#                                      each_serializer: serializer,
#                                      total: objects.total_count,
#                                      page: page,
#                                      per: per }
         format.html { render :index }
      end
   rescue ActionView::MissingTemplate
      respond_to do |format|
         format.json { head :ok, content_type: "application/json" }
         format.html { head :ok, content_type: "text/html" }
      end
   rescue Exception
      binding.pry
   end

   # POST /<objects>/create
   def create
      object.save!

      respond_to do |format|
         format.json { render json: object.jsonize(context) }
#         format.json { render json: object, serializer: serializer, locales: locales }
         format.jsonp { head :ok }
      end
   end

   # PUT /<objects>/1
   def update
      object.update!(permitted_params)

      respond_to do |format|
         format.json { render json: object.jsonize(context) }
#         format.json { render json: object, serializer: serializer, locales: locales }
         format.jsonp { head :ok }
      end
   end

   # GET /<objects>/1
   def show
      respond_to do |format|
         format.json { render json: object.jsonize(context) }
#         format.json { render :show, json: @object, locales: @locales,
#                                     serializer: serializer }
      end
   end

   # DELETE /<objects>/1
   def destroy
      object.destroy

      respond_to do |format|
         format.json { render json: object.jsonize(context) }
#         format.json { render :show, json: @object, locales: @locales,
#                                     serializer: serializer }
         format.jsonp { head :ok }
      end
   end

   # GET /<objects>/ac.json
   def ac
      @objects = apply_scopes(model)

      respond_to do |format|
         format.json {
            render json: {
               list: objects.limit(ac_limit).jsonize(ac_context),
               total: objects.total_count
            }
         }
      end
   end

#   def dashboard
#      settings = { settings: Tiun.settings, locales: @locales }
#
#      render inline: react_component('Dashboard', settings), layout: 'tiun'
#   end
#
   protected

   def model_name
      @@model_name ||= self.class.to_s.gsub(/.*::/, "").gsub("Controller", "").singularize
   end

   def param_name
      @@param_name ||= model_name.tableize
   end

   def model
      @@model ||= model_name.constantize
   end

#   def serializer
#      @serializer ||= "#{model_name}Serializer".constantize
#   end
#
#   def list_serializer
#      @list_serializer ||= "#{model_name}ListSerializer".constantize
#   end
#
   def policy
      @@policy ||= "#{model_name}Policy".constantize
   end

#   def objects_serializer
#      list_serializer.new(model: model)
#   end
#
   def apply_scopes model
      model
   end

#   def policy_name
#      @policy_name ||= Object.const_get(model.name + "Policy")
#   rescue NameError
#      @policy_name = Object.const_get("Tiun::#{model.name}Policy")
#   end
#
   def unprocessable_entity e
      errors = @object.errors.any? && @object.errors || e.to_s
      render json: errors, status: :unprocessable_entity
   end

   def ac_limit
      500
   end

   def context
      @@context ||= { except: supplement_names, locales: locales }
   end

   def ac_context
      @@ac_context ||= { only: %i(key value) }
   end

   def permitted_self
      @@permitted_self ||= model.attribute_types.keys #- [model.primary_key]
   end

   def permitted_children
      @@permitted_children ||= permitted_children
         model.nested_attributes_options.reduce({}) do |res, (name, opts)|
            child_model = model.reflections[name.to_s].klass
            value = child_model.attribute_types.keys
            value << :_destroy if opts[:allow_destroy]
            res[name] = value - supplement_names.map(&:to_s)

            res
         end
   end

   def permitted_params
      params.require(param_name).permit(*permitted_self, **permitted_children)
   end

   def supplement_names
      %i(created_at updated_at tsv)
   end

   def total
      %i(total_size total_count count).reduce(nil) do |count, method|
         objects.respond_to?(method) && !count ? objects.send(method) : count
      end
   end

   def paged_objects
      objects.page(page).per(per)
   end

   #

   def authorize!
      binding.pry
      if !policy.new(current_user, @object).send(action_name + '?')
         raise Tiun::Policy::NotAuthorizedError, "not allowed to do #{action_name} this #{@object.inspect}"
      end
   end

   def per
      @per ||= (params[:per] || 25).to_i
   end

   def page
      @page ||= (params[:page] || 1).to_i
   end

   def locales
      @locales ||= [I18n.locale]
   end

   def set_tokens
      @tokens ||= params[:with_tokens] || []
   end
#
#   def new_object
#      @object = model.new(permitted_params)
#   end
#
#   def fetch_objects
#      @objects = apply_scopes(model).page(params[:page])
#   end
#
#   def fetch_object
#      if params[:slug]
#         @object ||= model.by_slug(params[:slug])
#      else
#         @object ||= model.find(params[:id])
#      end || raise(ActiveRecord::RecordNotFound)
#   end
end
