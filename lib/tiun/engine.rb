require 'rails'
require 'active_record'

require 'tiun/model'

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

#   config.autoload_paths += %W(#{Tiun::Engine.root}/lib/tiun/autoloads)
#   config.autoload_paths += %W(#{Tiun::Engine.root}/lib/tiun/views)
   config.i18n.load_path += Dir[Tiun::Engine.root.join('lib', 'config', 'locale', '**', '*.{yaml,yml}')]

   config.to_prepare do
      ::ActiveRecord::Base.extend(Tiun::Model)
      Tiun.setup
   end
end

Engine = Tiun::Engine
