require "tiun/version"

module Tiun
#   extend ActiveSupport::Concern

   class << self
      def config
         @config || load_config
      end

      def load_config
         config = YAML.load(IO.read(Rails.root.join('config', 'tiun.yml')))

         parse_config(config)

         @config = config
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

      def parse_config config
         config["controllers"].each do |controller|
            model_name = -> { (controller["model"] || controller["name"]).titleize }
            names = -> { (controller["name"]).pluralize.titleize }
            name = -> { (controller["name"]).titleize }
            param = -> { controller["model"] || controller["name"] }
            params = -> { plain_hash([ 'id', controller[ "params" ]].compact.uniq ) }

            controller_rb = <<-RB
               class #{names[]}Controller < #{base_controller}
                  include Tiun::Base

                  def model
                     ::#{model_name[]} ;end

                  def object_serializer
                     Tiun::#{name[]}Serializer ;end

                  def objects_serializer
                     Tiun::#{names[]}Serializer ;end

                  def permitted_params
                     params.require( #{param[]} ).permit( #{params[]} ) ;end

               end
            RB

            policy_rb = <<-RB
               class #{model_name[]}Policy
                  include Tiun::Policy
               end
            RB

            class_eval(controller_rb)
            class_eval(policy_rb)
         end

         config
      end
   end

#   included do
#   end
end

require "tiun/base"
require "tiun/policy"
require "tiun/engine"
