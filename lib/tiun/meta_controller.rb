class Tiun::MetaController < ActionController::Base
   #before_action :authenticate_user!
   #before_action :authorize!

   # GET /meta/
   def index
      joint = Tiun.config.values.reduce({}) {|res, h| res.merge(h) }
#binding.pry
      render json: joint.as_json
   end
end

MetaController = Tiun::MetaController
