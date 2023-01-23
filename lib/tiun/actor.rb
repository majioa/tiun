require 'yaml'

module Tiun::Actor
   class InvalidActorKindError < StandardError; end
   class InvalidContextKindForActorError < StandardError; end

   AUTOMAP = {
      Validate: "tiun/actor/validate",
   }

   class << self
      def kinds
         @kinds ||= AUTOMAP.keys.map(&:to_s).map(&:downcase)
      end

      def actors
         @actors ||= AUTOMAP.keys.map do |const|
            require(AUTOMAP[const])
            [ const.to_s.downcase, const_get(const) ]
         end.to_h
      end

      def for! task, context
         actors[task.to_s] || raise(InvalidActorKindError)
      end

      def for task, context
         for!(task, context)
      rescue InvalidActorKindError
      end
   end
end

Actor = Tiun::Actor
