require 'rails'
require 'active_record'

class Tiun::Engine < ::Rails::Engine
   isolate_namespace Tiun

   engine_name 'tiun'

   paths["app"] << "lib"
   paths["app/controllers"] << "lib"
   paths["app/views"] << "lib"
#   paths["config"] << "lib/config"
#   paths["config/locales"] << "lib/locales"
   paths["config/routes.rb"]  << "lib/config/routes.rb"
#   require 'pry'
#   binding.pry

#  initializer "tiun", group: :all do |app|
#      PgHero.time_zone = PgHero.config["time_zone"] if PgHero.config["time_zone"]
      #

#  end

   config.autoload_paths += %W(#{Tiun::Engine.root}/lib/)
   config.autoload_paths += %W(#{Tiun::Engine.root}/lib/tiun/views)

   config.to_prepare do
      ::ActiveRecord::Base.extend(Tiun::Model)
      Tiun.setup
   end
end
