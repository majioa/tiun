Tiun::Engine.routes.draw do
#root to: redirect('/tiun/dashboard')
#scope module: 'tiun' do
      get '/meta' => 'meta#index'
#end
#get '/dashboard' => 'core#dashboard'

   Tiun.model_names.each do | model_name |
      resources model_name.pluralize, except: :edit
   end
end
