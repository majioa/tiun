module Tiun::Auth
   extend ActiveSupport::Concern

   included do
      before_action :authenticate_user
   end

   # TODO add automatic with list
   def current_user
      @current_user ||=
        #if session["user"] && user = User.where(id: session["user"]["id"]).first
         if session["user"] && user = User.with_user_names(auth_context).with_descriptions(auth_context).with_accounts(auth_context).where(id: session["user"]["id"]).first
            session_data = serialize_collection(user.update_session(session["user"]["refresh_token"]), auth_context)
            session.update("user" => session["user"].merge(session_data))

            user
         end
   rescue Tiun::Model::Auth::InvalidTokenError
      session.delete('user')

      nil
   end

   def authenticate_user
      current_user
   end

   def model_name
      @_model_name ||= self.class.to_s.gsub(/.*::/, "").gsub("Controller", "").singularize
   end

   def model
      @_model ||= model_name.constantize
   rescue NameError
      User
   end

   def get_properties for_object = nil
      @get_properties ||=
         if k = self.class.instance_variable_get(:@context)&.[](action_name)&.kind
            Tiun.type_attributes_for(k)
         else
            case for_object
            when ActiveRecord::Reflection, ActiveRecord::Associations, ActiveRecord::Scoping, ActiveRecord::Base
               for_object.model
            when Array
               for_object.find { |x| x.respond_to?(:attribute_types) } ||
                  for_object.find { |x| x.class.respond_to?(:attribute_types) }.class
            when Hash
               for_object.values.find { |x| x.respond_to?(:attribute_types) } ||
                  for_object.values.find { |x| x.class.respond_to?(:attribute_types) }.class
            when NilClass
               model
            else
               for_object
            end.attribute_types.keys
         end
   end

   def auth_context
      @auth_context ||= { except: supplement_names, locales: locales }
   end

   def context
      @context ||= { except: supplement_names, locales: locales }
   end

   def locales
      @locales ||= [I18n.locale]
   end

   def supplement_names
      %i(created_at updated_at tsv)
   end

   def serialize_collection collection, context = self.context
      collection.as_json(context.merge(only: get_properties(collection)))
   end

   def serialize object, context = self.context
      object.as_json(context.merge(only: get_properties(object)))
   end
end

Auth = Tiun::Auth
