module Tiun::Actor::Validate
   class << self
      def apply_to context
         context.valid?
      end
   end
end
