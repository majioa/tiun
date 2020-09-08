require 'rails/all'
require 'sqlite3'
require 'fileutils'

module Tiun
   class Application < Rails::Application
      dbconfig = YAML::load(IO.read("./spec/fixtures/rails/config/database.yml"))
      ActiveRecord::Base.establish_connection(dbconfig[Rails.env])

      FileUtils.rm_f(Rails.root.join('tiun_test'))
   end
end

require 'rspec/rails'
