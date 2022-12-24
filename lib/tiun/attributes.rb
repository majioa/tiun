require 'tiun/version'

module Tiun::Attributes
   AR_MAP = {
      "string" => "ActiveModel::Type::String",
      "integer" => "ActiveRecord::ConnectionAdapters::SQLite3Adapter::SQLite3Integer",
      "sequence" => "ActiveRecord::ConnectionAdapters::SQLite3Adapter::SQLite3Integer"
   }

   def attribute_name_for type
      type.name.singularize.camelize
   end

   def attribute_types_for model
      setup_if_not

      #binding.pry
      attributes.find {|a| a.name == model.name }
   end

   def attributes
      return @attributes if @attributes

      @attributes =
         types.map do |type|
            attribute_name = attribute_name_for(type)

            { name: attribute_name, attribute_map: migration_fields_for(type) }.to_os
         end
   end
end
