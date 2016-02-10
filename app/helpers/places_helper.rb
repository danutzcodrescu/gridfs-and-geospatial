module PlacesHelper
  def self.to_places(coll)
    result=[]
    coll.each do |place|
   		result<<Place.new(place)
   	end
  end
end