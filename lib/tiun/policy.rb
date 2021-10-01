module Tiun::Policy
   class NotAuthorizedError < StandardError; end

   extend ActiveSupport::Concern

   included do
      attr_reader :user, :record
   end

   def valid?
      true
   end

   def all?
      default?
   end

   def index?
      default?
   end

   def show?
      scope.where(id: record.id).exists?
   end

   def create?
      default?
   end

   def new?
      default?
   end

   def update?
      default?
   end

   def destroy?
      default?
   end

   def scope
      defined?(Pundit) && Pundit.policy_scope!(user, record.class) || ActiveRecord::Base
   end

   class Scope
      attr_reader :user, :scope

      def initialize(user, scope)
         @user = user
         @scope = scope
      end

      def resolve
         scope
      end
   end

   protected

   def initialize user, record
      @user = user
      @record = record
   end

   def default?
      user.respond_to?(:admin?) && user.admin?
   end
end
