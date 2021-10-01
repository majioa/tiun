begin
   require 'pry'
rescue NameError
end
require 'erb'
require 'action_controller'
require 'active_record'

require "tiun/mixins"
require "tiun/version"

module Tiun
   class NoRailsError < StandardError ;end
   class InvalidControllerError < StandardError ;end
   class InvalidModelError < StandardError ;end
#   extend ActiveSupport::Concern

   ControllerTemplate = ERB.new(IO.read(File.join(File.dirname(__FILE__), "tiun", "autocontroller.rb.erb")))
   ModelTemplate = ERB.new(IO.read(File.join(File.dirname(__FILE__), "tiun", "automodel.rb.erb")))
   MigrationTemplate = ERB.new(IO.read(File.join(File.dirname(__FILE__), "tiun", "automigration.rb.erb")))
   PolicyTemplate = ERB.new(IO.read(File.join(File.dirname(__FILE__), "tiun", "autopolicy.rb.erb")))
   SerializerTemplate = ERB.new(IO.read(File.join(File.dirname(__FILE__), "tiun", "autoserializer.rb.erb")))

   MAP = {
      'get' => {
         /index.json/ => 'index',
         /<\w+>.json/ => 'show',
      },
      'post' => 'create',
      'patch' => 'update',
      'put' => 'update',
      'delete' => 'destroy'
   }

   TYPE_MAP = {
      "string" => "string",
      "uri" => "string",
      "list" => nil,
      "json" => "jsonb",
      "enum" => "string",
   }

   AR_MAP = {
      "string" => "ActiveModel::Type::String",
      "integer" => "ActiveRecord::ConnectionAdapters::SQLite3Adapter::SQLite3Integer",
      "index" => "ActiveRecord::ConnectionAdapters::SQLite3Adapter::SQLite3Integer"
  }

   class << self

      def setup
         if defined?(::Rails) && ::Rails.root
            Dir.glob(::Rails.root&.join("config", "tiun", "*.yaml")) do |config|
               setup_with(config)
            end

            @setup = true
         end
      end

      def setup_if_not
         @setup ||= setup
      end

      def setup_with file
         config = append_config( file )
         # load_error_codes_from( config )
         # binding.pry
         load_types_from(config)
         load_attributes_from(config)
         load_migrations_from(config)
         load_models_from(config)
         load_policies_from(config)
         load_routes_from(config)
         load_controllers_from(config)
         load_serializers_from(config)

         config
      end

      def model_title_of context, name
         name = context.model || context.path&.split( /\// )&.slice(0...-1)&.last&.singularize

         name.blank? && raise(InvalidModelError) || name
      end

      def controller_title_of context, name
         name = context.controller || context.path&.split( /\// )&.slice(0...-1)&.join( "/" )&.pluralize

         name.blank? && raise(InvalidControllerError) || name
      end

      def migration_of context, name
         context.migration || "Create" + model_title_of(context, name).pluralize.camelize
      end

      def attribute_of context, name
         context[ 'attribute' ] || model_title_of( context, name ).singularize.camelize
      end

      def table_title_of context, name
         context.table || model_title_of(context, name).tableize
      end

      def policy_name_for context, name
         context.policy || model_title_of(context, name).camelize + "Policy"
      end

      def serializer_name_for context, name
         context.serializer || model_title_of(context, name).camelize + "Serializer"
      end

      def attribute_fields_for context, name
         migration_fields_for(context, name) | [{ name: "id", type: 'index', options: {}}]
      end

      def migration_fields_for context, name
         model = model_title_of(context, name)

         search_for(:types, model).fields.map do |attrs|
            type = detect_type(attrs.kind)
            type && { name: attrs.name, type: type, options: {} } || nil
         end.compact
      end

      def detect_type type_in
         type = TYPE_MAP[type_in]
         type || !type.nil? && "reference" || nil
         #type_in.split(/\s+/).reject {|x|x =~ /^</}.map do |type_tmp|
         #   type = TYPE_MAP[type_tmp] #.keys.find {|key| key == type_tmp}
         #   type || !type.nil? && "reference" || nil
         #end.compact.uniq.join("_")
      end

      def load_types_from config
         @types = types | (config.types || [])
         # TODO validated types
      end

      def action_names_of context, name
         actions = (context["methods"] || {}).map do |method|
            method_name = method.name
            rule = MAP[method_name]

            action = rule.is_a?(String) && rule || rule.reduce(nil) do |a, (re, action)|
               a || context.path =~ re && action || nil
            end

            # TODO validated types
            if ! action
               error :no_action_detected_for_resource_method, { name: name, method: method_name }
            end

            action
         end.compact

         if actions.blank?
            error :no_valid_method_defined_for_resource, { name: name }
         end

         actions
      end

      def string_eval string, name
         tokens = name.split("::")[0...-1]
         default = tokens[0].blank? && Object || Object.const_get(tokens[0])

         (tokens[1..-1] || []).reduce(default) do |o, token|
            o.const_set(token, Module.new)
         end

         eval(string)
      end

      def config_reduce config, default
         config.resources.reduce(default) do |res, context|
            if context.name.is_a?(String)
               yield(res, name, context)
            end

            res
         end
      end

      def load_attributes_from config
         config_reduce( config, attributes ) do |attributes, name, context|
            attribute = attribute_of( context, name )

            attributes << { name: attribute, attribute_map: attribute_fields_for(context, name) }.to_os
         end
      end

      def load_migrations_from config
         config_reduce( config, migrations ) do |migrations, name, context|
            migration = migration_of( context, name )

            if !search_for(:migrations, migration)
               table_title = table_title_of( context, name )
               migration_fields = migration_fields_for( context, name )
               code = MigrationTemplate.result(binding)
               migrations << { name: migration, code: code }.to_os
               string_eval(code, migration)
            end

            migrations
         end
      end

      def load_models_from config
         config_reduce( config, models ) do |models, name, context|
            model_title = model_title_of( context, name )
            model_name = model_title.camelize
            model = model_for( model_name )

            if !model && !search_for(:models, model_name)
               code = ModelTemplate.result(binding)
               models << { name: model_name, code: code }.to_os
               string_eval(code, model_name)
            end

            models
         end
      end

      def load_policies_from config
         config_reduce( config, policies ) do |policies, name, context|
            policy_name = policy_name_for( context, name )

            if !search_for(:policies, policy_name)
               code = PolicyTemplate.result(binding)
               policies << { name: policy_name, code: code }.to_os
               string_eval(code, policy_name)
            end

            policies
         end
      end

      def load_serializers_from config
         config_reduce( config, serializers ) do |policies, name, context|
            serializer_name = serializer_name_for( context, name )

            if !search_for(:serializers, serializer_name)
               code = SerializerTemplate.result(binding)
               serializers << { name: serializer_name, code: code }.to_os
               string_eval(code, serializer_name)
            end

            serializers
         end
      end

      def load_controllers_from config
         config_reduce( config, controllers ) do |controllers, name, context|
            controller_title = controller_title_of( context, name )
            model_title = model_title_of( context, name )
            controller = controller_title.camelize + 'Controller'

            if !search_for(:controllers, controller)
               model = model_title.camelize
               code = ControllerTemplate.result(binding)
               controllers << { name: controller, code: code }.to_os
               string_eval(code, controller)
            end

            controllers
         end
      end

      def draw_routes e
         setup_if_not
         e.get('/meta' => 'meta#index')
         routes.each do |path, respond|
            e.get(path => respond)
         end
      end

      def load_routes_from config
         config_reduce( config, routes ) do |r, name, context|
            controller = controller_title_of( context, name )
            actions = action_names_of( context, name )

            actions.each do |action|
               path = /(?<pre>.*)<(?<key>\w+)>(?<post>.*)/ =~ context['path'] &&
                  "#{pre}:#{key}#{post}" || context[ 'path' ]

               #  binding.pry # ? TODO
               if r.select {|x|x.name == path}.blank?
                  r << { path: path, route_name: "#{controller}##{action}" }
                  #Tiun::Engine.routes.draw do
                  #   r << { path: path, route: get( path => "#{controller}##{action}" ) }
                  #end
               end
            end

            r
         end
      end

      def attribute_types_for model
         setup_if_not

         attributes.find {|a| a.name == model.name }
      end

      def search_for kind, value
         send(kind).find {|x| x.name == value }
      end

      def search_all_for kind, value
         send(kind).select {|x| x.name == value }
      end

      def error_codes
         @error_codes ||= []
      end

      def types
         @types ||= []
      end

      def models
         @models ||= []
      end

      def attributes
         @attributes ||= []
      end

      def migrations
         @migrations ||= []
      end

      def policies
         @policies ||= []
      end

      def serializers
         @serializers ||= []
      end

      def controllers
         @controllers ||= []
      end

      def routes
         @routes ||= []
      end

      def config
         @config ||= {}
      end

      def errors
         @errors ||= []
      end

      def append_config file
         c = YAML.load(IO.read( file )).to_os
         config[ File.expand_path( file )] = c
      end

      def settings
         @settings ||= setup_classes(tiuns.map { | model | [ model.name.underscore.to_sym, model.tiun ]}.to_h)
      end

      def tiuns
         Rails.configuration.paths['app/models'].to_a.each do | path |
            Dir.glob("#{path}/**/*.rb").each { |file| require(file) }
         end

         ActiveRecord::Base.tiuns
      end

      def model_names
         settings.keys.map(&:to_s)
      end

      def model_for model_name
         model_name.constantize
      rescue NameError
      end

      def base_model
         @base_model ||= ActiveRecord::Base
      end

      def base_controller
         @base_controller ||= ActionController::Base
      end

      def base_migration
         @base_migration ||= ActiveRecord::Migration[5.2]
      end

      def error code, options
         errors << { code: code, options: options }
      end

      def valid?
         errors.blank?
      end

      def migrate
         @up_migrator.nil? && (
            @up_migrator = ActiveRecord::Migrator.new(:up, self.migrations.keys.map(&:constantize))
#binding.pry
            @up_migrator.migrate
         )
      end

      def rollback
         @down_migrator.nil? && (
            @down_migrator = ActiveRecord::Migrator.new(:down, self.migrations.keys.map(&:constantize))
#binding.pry
            @down_migrator.migrate
         )
      end

#      def type_of kind
#         case kind
#         when 'string'
#            :"ActiveModel::Type::String"
#         when 'integer', 'index'
#            :"ActiveRecord::ConnectionAdapters::SQLite3Adapter::SQLite3Integer"
#         else
#            error :invalid_attribute_type_for_kind, { kind: kind }
#         end
#      end
#      def plain_parm parm
#         case parm
#         when String
#            array = parm.split( /\s*,\s*/ )
#
#            if array.size > 1
#               plain_array( array )
#            else
#               array.first.to_sym
#            end
#         when Hash
#            plain_hash( parm )
#         when Array
#            plain_array( parm )
#         else
#            nil
#         end
#      end
#
#      def plain_hash hash
#         hash.map do |( key, parms )|
#            [ key.to_sym, plain_parm( parms )]
#         end.to_h
#      end
#
#      def plain_array array
#         array.map do | parm |
#            plain_parm( parm )
#         end.flatten
#      end
#
      def setup_classes settings
         settings.each do | (model_name, tiun) |
            name = -> { model_name.to_s.camelize }
            names = -> {  model_name.to_s.pluralize.camelize }
            params = -> { tiun[ :fields ].keys }

            controller_rb = <<-RB
               class #{names[]}Controller < #{base_controller}
                  include Tiun::Base

                  def model
                     ::#{name[]} ;end

                  def object_serializer
                     #{name[]}Serializer ;end

                  def objects_serializer
                     #{names[]}Serializer
                  rescue NameError
                     Tiun::PagedCollectionSerializer ;end

                  def permitted_params
                     params.require( '#{model_name}' ).permit( #{params[]} ) ;end;end
            RB

            policy_rb = <<-RB
               class #{name[]}Policy
                  include Tiun::Policy
               end
            RB

            class_eval(controller_rb)
            class_eval(policy_rb)
         end
      end

      def root
         Gem::Specification.find_by_name( "tiun" ).full_gem_path
      end

   end

#   included do
#   end
end

require "tiun/base"
require "tiun/policy"
require "tiun/engine"
