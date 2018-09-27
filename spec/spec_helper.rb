ENV['RAILS_ENV']='test'

require 'pry'
require "bundler/setup"
require 'match_hash'

require "tiun"
require_relative 'fixtures/rails/config/environment'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
