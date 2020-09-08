require 'rails_helper'
require 'action_dispatch'

RSpec.describe Tiun::CoreController do
   include RSpec::Rails::Matchers::RoutingMatchers
   #include ActionDispatch::Assertions
   #include ActionController::TestCase::Behavior
   include ::RSpec::Rails::SystemExampleGroup

   before do
      Tiun.setup_with('spec/fixtures/samples/users.yaml')
   end

   describe "tiun countroller" do
     subject { Tiun.controllers.first.first.constantize.new }

      xcontext "action" do
         before { 
        binding.pry
           get :show, params: { id: "1" } }
         it {} 
      end

     xcontext "routing" do
         it { 
     #it { is_expected.to respond_with(:ok) }
      #   is_expected.to render_template(:index)
           #expaect(get: "/v1/users/:id.json").to route_to("users#show")
        }
      end
   end
end
