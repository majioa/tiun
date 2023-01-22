begin
   require 'pry'
rescue NameError, LoadError
end
require 'erb'
require 'action_controller'
require 'active_record'

require "tiun/mixins"
require "tiun/version"
require "tiun/migration"
require "tiun/attributes"
require "tiun/base"
require "tiun/core_helper"

module Tiun
   class NoRailsError < StandardError ;end
   class InvalidControllerError < StandardError ;end
   class InvalidModelError < StandardError ;end
#   extend ActiveSupport::Concern
   extend Tiun::Migration
   extend Tiun::Attributes

   MAP = {
      'get' => {
         %r{(?:/(?<c>[^:/]+)).json} => 'index',
         %r{(?:/(?<c>[^/]+)/:[^/]+).json} => 'show',
      },
      'post' => 'create',
      'patch' => 'update',
      'put' => 'update',
      'delete' => 'destroy'
   }

   TYPE_MAP = {
      "string" => "string",
      "sequence" => "integer",
      "uri" => "string",
      "list" => nil,
      "json" => "jsonb",
      "enum" => "string",
   }

   TEMPLATES = {
      model: ERB.new(IO.read(File.join(File.dirname(__FILE__), "tiun", "automodel.rb.erb"))),
      policy: ERB.new(IO.read(File.join(File.dirname(__FILE__), "tiun", "autopolicy.rb.erb"))),
      controller: ERB.new(IO.read(File.join(File.dirname(__FILE__), "tiun", "autocontroller.rb.erb"))),
#      list_serializer: ERB.new(IO.read(File.join(File.dirname(__FILE__), "tiun", "autolistserializer.rb.erb"))),
#      serializer: ERB.new(IO.read(File.join(File.dirname(__FILE__), "tiun", "autoserializer.rb.erb")))
   }

   class << self
      def setup
         if defined?(::Rails) && ::Rails.root && !@config
            files = Dir.glob(::Rails.root&.join("config", "tiun", "*.{yml,yaml}")) |
                    Dir.glob(::Rails.root&.join("config", "tiun.{yml,yaml}"))

            setup_with(*files)
         end
      end

      def setup_if_not
         @setup ||= setup
      end

      def setup_with *files
         setup_migrations

         files.each do |file|
            config = append_config(file)
            # load_error_codes_from( config )
            load_types_from(config)
            load_defaults_from(config)
            %i(model controller policy).each do |kind|
               instance_variable_set("@#{kind.to_s.pluralize}", parse_objects(kind, config))
            end
            load_routes_from(config)
         end

         # validates
         config
      end

      def model_name_for context
         context.model ||
            %r{(?:/(?<c>[^/]+)/:[^/]+|/(?<c>[^:/]+)).json} =~ context.path && c ||
            context.name.split(".").first
      end

      def controller_name_for context
         context.controller ||
            %r{^(?:(?<c>.+)/:[^/]+|/(?<c>[^:]+)).json} =~ context.path && c ||
            context.name.split(".").first
      end

      def model_title_for context
         name = model_name_for(context)

         name ? name.singularize.camelize : raise(InvalidModelError)
      end

      def controller_title_for context
         name = controller_name_for(context)

         name ? name.pluralize.camelize + 'Controller' : raise(InvalidControllerError)
      end

      def route_title_for context
         name = controller_name_for(context)

         name ? name.pluralize : raise(InvalidControllerError)
      end

      def table_title_for context
         context.table || model_name_for(context).tableize
      end

      def table_title_for type
         type.name.tableize
      end

      def policy_title_for context
         context.policy || model_name_for(context).singularize.camelize + "Policy"
      end

#      def serializer_title_for context
#         context.serializer || model_name_for(context).singularize.camelize + "Serializer"
#      end
#
#      def list_serializer_title_for context
#         context.list_serializer || model_name_for(context).singularize.camelize + "ListSerializer"
#      end
#
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
      end

      def action_names_for context
         actions = (context["methods"] || {}).map do |method|
            method_name = method.name
            rule = MAP[method_name]

            action = rule.is_a?(String) && rule || rule.reduce(nil) do |a, (re, action)|
               a || context.path =~ re && action || nil
            end

            # TODO validated types
            if ! action
               error :no_action_detected_for_resource_method, { name: context.name, method: method_name }
            end

            action ? [action, method] : nil
         end.compact.to_h

         if actions.blank?
            error :no_valid_method_defined_for_resource, { name: context.name }
         end

         actions
      end

      def string_eval string, name
         tokens = name.split("::")[0...-1]
         default = tokens[0].blank? && Object || Object.const_get(tokens[0])

         (tokens[1..-1] || []).reduce(default) do |o, token|
            o.constants.include?(token.to_sym) && o.const_get(token) || o.const_set(token, Module.new)
         end

         eval(string)
      end

      def config_reduce config, default
         config.resources.reduce(default) do |res, context|
            if context.name.is_a?(String)
               yield(res, context.name, context)
            else
               res
            end
         end
      rescue NoMethodError
         error :no_resources_section_defined_in_config, {config: config, default: default}

         []
      end

      def load_defaults_from config
         @defaults = defaults.to_h.merge(config.defaults.to_h).to_os
      end

      def parse_objects kind, config
         config_reduce(config, send(kind.to_s.pluralize)) do |res, name, context|
            object_name = send("#{kind}_title_for", context)

            unless search_for(kind.to_s.pluralize, object_name)
               object_in = constantize(object_name)
               code = TEMPLATES[kind].result(binding)
               object = string_eval(code, object_name)

               res | [{ name: object_name, code: code, const: object }.to_os]
            else
               res
            end
         end
      end

      def load_routes_from config
         @routes =
         config_reduce(config, routes) do |r, name, context|
            controller = route_title_for(context)
            actions = action_names_for(context)

            actions.reduce(r) do |res, (action, method)|
               /(\.(?<format>[^.]+))$/ =~ context.path

               path =
                  /(?<pre>.*)<(?<key>\w+)>(?<post>.*)/ =~ context.path &&
                  "#{pre}:#{key}#{post}" || context.path

               if res.select {|x| x[:uri] == path }.blank?
                  attrs = { uri: path, path: "#{controller}##{action}", kind: method.name }
                  attrs = attrs.merge(options: {defaults: { format: format }, constraints: { format: format }}) if format

                  res | [attrs]
               else
                  res
               end
            end
         end
      end

      def default_route
         {
            uri: '/meta.json',
            path: 'meta#index',
            kind: 'get',
            options: { defaults: { format: 'json' }, constraints: { format: 'json' }}
         }
      end

      def draw_routes e
         setup_if_not
         routes.each do |route|
            attrs = { route[:uri] => route[:path] }.merge(route[:options])
            e.send(route[:kind], **attrs)
         end
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

      def policies
         @policies ||= []
      end

#      def serializers
#         @serializers ||= []
#      end
#
#      def list_serializers
#         @list_serializers ||= []
#      end
#
      def controllers
         @controllers ||= []
      end

      def routes
         @routes ||= [default_route]
      end

      def config
         @config ||= {}
      end

      def defaults
         @defaults ||= {}.to_os
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
         ::Rails.configuration.paths['app/models'].to_a.each do | path |
            Dir.glob("#{path}/**/*.rb").each { |file| require(file) }
         end

         ActiveRecord::Base.tiuns
      end

#      def model_names
#         settings.keys.map(&:to_s)
#      end
#
      def constantize name
         name.constantize
      rescue NameError
      end

      def base_model
         @base_model ||= ActiveRecord::Base
      end

      def base_controller
         @base_controller ||= ActionController::Base
      end

      def error code, options
         errors << { code: code, options: options }
      end

      def valid?
         errors.blank?
      end

      #def target_version
      #
      #end

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
            names = -> { model_name.to_s.pluralize.camelize }
            params = -> { tiun[:fields].map(&:first) }

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
