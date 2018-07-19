Tiun::Engine.routes.draw do
   Tiun.config["controllers"].each do |controller|
      resources controller["name"].pluralize, except: :edit
   end
end
