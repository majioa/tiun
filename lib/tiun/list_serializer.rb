module ::Tiun::ListSerializer
   def as_json *_args
      serializable_hash
   end

   def to_json *_args
      serializable_hash
   end

   def serializable_hash(*_args)
      binding.pry
      {
         list: super,
         page: @options[:page] || 1,
         total: @options[:total] || @object.count
      }
   end
end

ListSerializer = ::Tiun::ListSerializer
