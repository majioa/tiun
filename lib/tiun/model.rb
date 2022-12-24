require 'tiun/version'

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
      ## return self.instance_variable_get(:@tiun) if self.instance_variables.include?(:@tiun)

      ## self.instance_variable_set(:@tiun, { fields: _tiun_parse_model})

      ## tiuns = self.class.instance_variables.include?(:@tiun) && self.class.instance_variable_get(:@tiuns) || []
      ## tiuns << self
      ## self.class.instance_variable_set(:@tiuns, tiuns)
      #
      # belongs_to, has_many, has_one
   end

   # +tiuns+ returns lists of the tiuned models. In case the list is absent returns blank
   # +Array+.
   #
   # Examples:
   #
   #     Model.tiuns # => [ Model ]
   #
   #     ActiveRecord::Base.tiuns # => []
   #
   def tiuns
      self.class.instance_variable_get(:@tiuns) || [] ;end

   def attribute_types
      @_tiun_attribute_types ||= Tiun.attribute_types_for(self) || super ;end

   protected

    # :nodoc:
   def _tiun_parse_model
      self.attribute_types.map do |( name, attr )|
         if !["created_at", "updated_at"].include?( name )
            kind = case attr.class.to_s.split("::").last
            when /Integer|SQLite3Integer/
               :integer
            when "String"
               :string
            when "Text"
               :text
            when /DateTime|TimeZoneConverter/
               :datetime
            when "Date"
               :date
            when "Time"
               :time
            when "Boolean"
               :boolean
            else
            end

            if kind
               props = { type: kind }
               props[ :size ] = attr.limit if attr.limit

               [name.to_sym, props]
            end
         end
       end.compact.to_h
    rescue ActiveRecord::ConnectionNotEstablished
       [] end

   #TODO
   #defaults fields: :user
   #  tiun as: :branch /as: :is
   #  include user(without *_at)/all fields (to list/form),
   #  all scopes (to list),
   #  all havings - has_many/ones (to form)
   # tiunable_by :field/s - for text search by this field/s
      end
