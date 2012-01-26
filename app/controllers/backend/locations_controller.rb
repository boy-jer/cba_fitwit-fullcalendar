class Backend::LocationsController < Backend::ResourceController

  respond_to :json, only: [:show]
   def show
     @map = true
     super
   end

   def calendar
     @calendar = true
     @location = Location.find(params[:location_id])
   end
end
