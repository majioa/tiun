module Tiun::Serializer
   class UndefinedModelError < StandardError; end

   def self.included kls
      kls.class_eval do
         def initialize model = nil
            raise UndefinedModelError if !model

            @model = model
         end
      end
   end

   def as_json *args
      serializable_hash
   end

   def serializable_hash
      {
      }
   end
end
