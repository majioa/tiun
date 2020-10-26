class Tiun::Serializer
   class UndefinedModelError < StandardError; end

   def initialize model = nil
      raise UndefinedModelError if !model
   end

   def as_json *args
      serializable_hash
   end

   def serializable_hash
      {
      }
   end
end
