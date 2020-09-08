require 'acceptance_spec_helper'

RSpec.describe 'shoulda-matchers integrates libs for cucumber framework' do
   before do
      create_rails_application

      write_file 'db/migrate/1_create_users.rb', <<-FILE
         class CreateUsers < ActiveRecord::Migration
            def self.up
               create_table :users do |t|
                  t.string :name
               end
            end
         end
      FILE

      run_rake_tasks(*%w(db:drop))
      run_rake_tasks!(*%w(db:create db:migrate))

      write_file 'app/models/user.rb', <<-FILE
         class User < ActiveRecord::Base
            tiun

            validates_presence_of :name
            validates_uniqueness_of :name
         end
      FILE

      write_file 'features/support/env.rb', <<-FILE
      require 'cucumber/rails'
      require 'shoulda-matchers/cucumber'

      Shoulda::Matchers.configure do |config|
         config.integrate do |with|
            with.test_framework :cucumber
            with.library :rails end;end
      FILE

      write_file 'lib/tasks/cucumber.rake', <<-FILE
      require 'cucumber/rake/task'

      Cucumber::Rake::Task.new(:cucumber) do |t|
         t.cucumber_opts = "features --format pretty"
      end
      FILE

      write_file 'features/step_definitions/user_model_steps.rb', <<-FILE
      Given("default User model") do
         User.create(name: "Vasja")
      end

      Then("the model is valid") do
         expect(User.first).to validate_presence_of(:name)
      end
      FILE

      write_file 'features/user_model.feature', <<-FILE
      Feature: User model

      Scenario: Valid model of User
         Given default User model
         Then the model is valid
      FILE

      write_file 'features/fixtures/users.yaml', <<-FILE
---
project.user.id:
   path: /v1/users/<id>.json
   descriptions:
      en: This allows accessing to the specified model record by <id> URI-parameter. Added into API v1.0.
   methods:
      get:
         version: 1.0
         descriptions:
            en: Gets properties of the user record specified by <id> URI-parameter, and returns then as JSON. Do not poll this method more than once an hour.
         auth: no
         errors:
            200:
               name: OK
               descriptions:
                  en: The resource was found and is accessible. Returned data responds to the current state of the resource.
            422.3:
               name: SSL is required
               descriptions:
                  en: SSL is required to access the Vridlo API.
            404:
               name: Not Found
               descriptions:
                  en: The record with provided id is not found.
            500:
               name: Internal Server Error
               descriptions:
                  en: The Internal Server Error has occurred.
      FILE

      updating_bundle do
      end
   end

   context 'when using both active_record and active_model libraries' do
      xit 'allows the use of matchers from both libraries' do
         result = run_rake_tasks 'cucumber'
         binding.pry
         expect(result).to have_output('passed')
      end
   end
end

