require 'rails'
require 'active_support'

require "tiun/version"

module Tiun
#   extend ActiveSupport::Concern

   class << self
      def settings
         @settings ||= setup_classes(tiuns.map { | model | [ model.name.underscore, model.tiun ]}.to_h)
      end

      def tiuns
         Rails.configuration.paths['app/models'].to_a.each do | path |
            Dir.glob("#{path}/**/*.rb").each { |file| require(file) }
         end

         ActiveRecord::Base.tiuns
      end

      def model_names
         settings.keys
      end

      def base_controller
         @base_controller ||= ActionController::Base
      end

         def plain_parm parm
            case parm
            when String
               array = parm.split( /\s*,\s*/ )

               if array.size > 1
                  plain_array( array )
               else
                  array.first.to_sym
               end
            when Hash
               plain_hash( parm )
            when Array
               plain_array( parm )
            else
               nil
            end
         end

         def plain_hash hash
            hash.map do |( key, parms )|
               [ key.to_sym, plain_parm( parms )]
            end.to_h
         end

         def plain_array array
            array.map do | parm |
               plain_parm( parm )
            end.flatten
         end

      def setup_classes settings
         settings.each do | (model_name, tiun) |
            name = -> { model_name.titleize }
            names = -> { model_name.pluralize.titleize }
            params = -> { tiun[ :fields ].keys }

            controller_rb = <<-RB
               class #{names[]}Controller < #{base_controller}
                  include Tiun::Base

                  def model
                     ::#{name[]} ;end

                  def object_serializer
                     Tiun::#{name[]}Serializer ;end

                  def objects_serializer
                     Tiun::#{names[]}Serializer ;end

                  def permitted_params
                     params.require( #{name[]} ).permit( #{params[]} ) ;end

               end
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
   end

#   included do
#   end
end

require "tiun/base"
require "tiun/policy"
require "tiun/engine"
