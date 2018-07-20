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

      before_action :authenticate_user!, except: %i(dashboard)
      before_action :set_tokens, only: %i(index)
      before_action :set_page, only: %i(index)
      before_action :set_locales
      before_action :new_object, only: %i(create)
      before_action :fetch_object, only: %i(show update destroy)
      before_action :fetch_objects, only: %i(index)
      before_action :authorize!, except: %i(dashboard)

      rescue_from ActiveRecord::RecordNotUnique,
                  ActiveRecord::RecordInvalid,
                  ActiveRecord::RecordNotSaved,
                  ActiveRecord::RecordNotFound, with: :unprocessable_entity

#      has_scope :with_token, only: %i(index all)
#      has_scope :with_tokens, only: %i(index), type: :array

   end

   # GET /<objects>/
   def index
      respond_to do |format|
         format.json { render :index, json: @objects, locales: @locales,
                                      serializer: objects_serializer,
                                      total: @objects.total_count,
                                      page: @page,
                                      each_serializer: object_serializer }
         format.html { render :index } end
   rescue ActionView::MissingTemplate
      head :ok, content_type: "text/html" ;end

   # POST /<objects>/create
   def create
      @object.save!

      render json: @object, serializer: object_serializer, locales: @locales ;end

   # PUT /<objects>/1
   def update
      @object.update!( permitted_params )

      render json: @object, serializer: object_serializer, locales: @locales ;end

   # GET /<objects>/1
   def show
      respond_to do |format|
         format.json { render :show, json: @object, locales: @locales,
                                     serializer: object_serializer } ;end;end

   # DELETE /<objects>/1
   def destroy
      @object.destroy

      respond_to do |format|
         format.json { render :show, json: @object, locales: @locales,
                                     serializer: object_serializer } ;end;end

   def ql
      @list = apply_scopes(model)

      respond_to do |format|
         format.json { render :index, json: @list.limit(500),
                                      locales: @locales,
                                      serializer: Tiun::AutocompleteSerializer,
                                      total: @calendaries.count,
                                      each_serializer: Tiun::QlSerializer }
      end;end

   def dashboard
      settings = { settings: Tiun.settings, locales: @locales }

      render inline: react_component('Dashboard', settings), layout: 'tiun'
   end

   protected

   def apply_scopes model
      model
   end

   def policy_name
      @policy_name ||= Object.const_get(model.name + "Policy")
   rescue NameError
      @policy_name = Object.const_get("Tiun::#{model.name}Policy")
   end

   def authorize!
      if !policy_name.new(current_user, @object).send(action_name + '?')
         raise Pundit::NotAuthorizedError, "not allowed to do #{action_name} this #{@object.inspect}" ;end;end

   def unprocessable_entity e
      errors = @object.errors.any? && @object.errors || e.to_s
      render json: errors, status: :unprocessable_entity ;end

   def set_page
      @page ||= (params[:page] || 1).to_i ;end

   def set_locales
      @locales ||= [ I18n.locale ] ;end

   def set_tokens
      @tokens ||= params[:with_tokens] || [] ;end

   def new_object
      @object = model.new( permitted_params ) ;end

   def fetch_objects
      @objects = apply_scopes( model ).page( params[:page] ) ;end

   def fetch_object
      if params[:slug]
         @object ||= model.by_slug(params[:slug])
      else
         @object ||= model.find(params[:id]) ;end ||
            raise(ActiveRecord::RecordNotFound) ;end;end
