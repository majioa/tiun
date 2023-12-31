module Routes
   Mime::Type.register "application/jsonp", :jsonp

   Tiun::Engine.routes.draw do
#root to: redirect('/tiun/dashboard')
#scope module: 'tiun' do
      Tiun.draw_routes(self)
 #     get('/v1/users/:id.json' => '/v1/users#show')
##end
#get '/dashboard' => 'core#dashboard'

   #Tiun.model_names.each do | model_name |
   #   resources model_name.pluralize, except: :edit
   #end
   end
end
