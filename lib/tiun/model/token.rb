require 'tiun/model'

module Tiun::Model::Token
   class << self
      def included kls
         kls.module_eval do
            scope :actual, -> { where("expires_at >= ?", Time.zone.now) }
         end
      end
   end
end

Model::Token = Tiun::Model::Token
