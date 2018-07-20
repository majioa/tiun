module Tiun::Model
   # +tiun+ sets up tiuner for the model. This exports corresponding record fields to default
   # dashboard method, which loads the react component. When the model has been set up, the method
   # returns the compiled data of the model.
   #
   # Examples:
   #
   #     tiun
   #
   #     Model.tiun
   #
   def tiun
      return self.instance_variable_get(:@tiun) if self.instance_variables.include?(:@tiun)

      self.instance_variable_set(:@tiun, { fields: _tiun_parse_model})

      tiuns = self.class.instance_variables.include?(:@tiun) && self.class.instance_variable_get(:@tiuns) || []
      tiuns << self
      self.class.instance_variable_set(:@tiuns, tiuns) ;end

   # +tiuns+ lists tiuned models.
   #
   # Examples:
   #
   #     Model.tiuns
   #
   def tiuns
      self.class.instance_variable_get(:@tiuns)
   rescue NameError
      nil ;end

   protected

   # :nodoc:
   def _tiun_parse_model
      self.attribute_types.map do |( name, attr )|
         if !["created_at", "updated_at"].include?( name )
            kind = case attr.class.to_s.split("::").last
            when "Integer"
               :integer
            when "String"
               :string
            when "DateTime"
               :datetime
            else
            end

            if kind
               props = { type: kind }
               props[ :size ] = attr.limit if attr.limit

               [name, props]
            end
         end
      end.compact.to_h ;end

   #TODO
   #defaults fields: :user
   #  tiun as: :branch /as: :is
   #  include user(without *_at)/all fields (to list/form),
   #  all scopes (to list),
   #  all havings - has_many/ones (to form)
   # tiunable_by :field/s - for text search by this field/s
      end
