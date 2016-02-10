class Place
	include ActionView::Helpers
	attr_accessor :id, :formatted_address, :location, :address_components

	def self.mongo_client
		Mongoid::Clients.default
	end

	def self.collection
		self.mongo_client['places']
	end

	def self.load_all(file_path) 
	    file=File.read(file_path)
	    hash=JSON.parse(file)
	    collection.insert_many(hash)
  	end

  	def initialize(params={})
  		@id=params[:_id].to_s
	    @address_components= params[:address_components].map {|a| AddressComponent.new(a)}
	    @formatted_address= params[:formatted_address]
	    @location = Point.new(params[:geometry][:geolocation])
  	end

  	def self.find_by_short_name (short_name)
		result = self.collection.find( { 'address_components.short_name' => short_name })
	end

	def self.find id
		result=collection.find({:_id=>BSON::ObjectId.from_string(id.to_s)}).first
		Place.new(result)
	end

	def self.all (offset=0, limit=nil)
		result=collection.find().skip(offset)
		result=result.limit(limit) if !limit.nil?
		array=[]
		result.map do |place|
			array <<Place.new(place)
		end
		array
	end

	def destroy
		self.class.collection
              .delete_one 
	end

	def self.to_places(coll)
    result=[]
    coll.map do |place|
   		result << Place.new(place)
   	end
   	result
  end
end