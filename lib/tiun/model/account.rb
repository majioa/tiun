require 'tiun/model'

module Tiun::Model::Account
   class InvalidPasswordError < StandardError; end

   def authenticated_user! password
      user.match_password?(password) ? user : raise(InvalidPasswordError)
   end

   def create_validate_token
      Token::Validate.create(tokenable: self)
   end

   def validate_token
      tokina.where(type: "Token::Validate").first
   end

   class << self
      def included kls
         kls.module_eval do
            belongs_to :user
            has_many :tokina, as: :tokenable

            after_create :create_validate_token
         end
      end
   end
end

Model::Account = Tiun::Model::Account
