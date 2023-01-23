class Object
   def blank?
      case self
      when NilClass, FalseClass
         true
      when TrueClass
         false
      when Hash, Array
         !self.any?
      else
         self.to_s == ""
      end
   end

   def to_os
      if self.respond_to?(:to_h)
         if self.is_a?(OpenStruct)
            self
         else
            OpenStruct.new(self.to_h.map {|(x, y)| [x.to_s, y.respond_to?(:map) && y.to_os || y] }.to_h)
         end
      else
         OpenStruct.new("" => self)
      end
   rescue
      binding.pry
   end
end

class Array
   def to_os
      self.map {|x| x.to_os }
   end
end

class OpenStruct
   def map *args, &block
      res = self.class.new

      self.each_pair do |key, value|
         res[key] = block[key, value]
      end

      res
   end
end

Mixins = Object
