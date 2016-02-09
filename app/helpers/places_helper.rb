module PlacesHelper
  def to_places(coll)
     result = coll.map { |place| 
     	Place.new(place) 
     }   
   	 return result
  end
end