class Tiun::CoreController < ActionController::Base
   include Tiun::CoreHelper
   include Tiun::Base
end

CoreController = Tiun::CoreController
