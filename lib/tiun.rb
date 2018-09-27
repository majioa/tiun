#require 'active_support'

require "tiun/version"

module Tiun
#   extend ActiveSupport::Concern

   class << self
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

      def base_controller
         @base_controller ||= ActionController::Base
      end

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
   end

#   included do
#   end
end

require "tiun/base"
require "tiun/policy"
require "tiun/engine"
