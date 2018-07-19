class Tiun::Engine < ::Rails::Engine
   isolate_namespace Tiun

   engine_name 'tiun'

   paths["config/routes.rb"]  << "lib/config/routes.rb"

   initializer "tiun", group: :all do |app|
#      PgHero.time_zone = PgHero.config["time_zone"] if PgHero.config["time_zone"]
      #

   end

   config.to_prepare do
      Tiun.load_config
#      Dir.glob(Rails.root + "app/decorators/**/*_decorator*.rb").each do |c|
#         require_dependency(c)
#      end
   end
end
