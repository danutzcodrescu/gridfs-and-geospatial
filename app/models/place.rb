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
	    @address_components= params[:address_components].map {|a| AddressComponent.new(a)} if !params[:address_components].nil?
	    @formatted_address= params[:formatted_address]
	    @location = Point.new(params[:geometry][:geolocation])
  	end

  	def self.find_by_short_name (short_name)
		result = self.collection.find( { 'address_components.short_name' => short_name })
	end

	def self.find id
		result=collection.find({:_id=>BSON::ObjectId.from_string(id.to_s)}).first
		result.nil? ? nil: Place.new(result)
	end

	def self.all (offset=0, limit=nil)
		result=collection.find().skip(offset)
		result=result.limit(limit) if !limit.nil?
		array=[]
		result.map do |place|
			array << Place.new(place)
		end
		array
	end

	def destroy
		self.class.collection.find({_id: BSON::ObjectId.from_string(@id)}).delete_one 
	end
	
	def self.get_address_components( sort={:_id => 1}, offset=0, limit=9999999999999)

			self.collection.find().aggregate([{:$project=> {"_id" => 1, "address_components" => 1, "formatted_address" => 1, "geometry.geolocation" => 1}},
											{:$unwind => '$address_components'},{:$sort=>sort},{:$skip=> offset},{:$limit=>limit}])

	end
	
	def self.get_country_names
		result = self.collection.find().aggregate([{:$match => {"types"=>"country"}}, {:$project => {"address_components.long_name"=>1, "address_components.types"=>1}}, 
											{:$unwind =>"$address_components"}, {:$group=>{ :_id=>'$address_components.long_name'}}])
		return result.to_a.map{ |h| h[:_id]}									
	end
	
	def self.find_ids_by_country_code (code)
		result = self.collection.find().aggregate([{:$match => {"address_components.short_name" => code}}, {:$project => {"_id" => 1}}])
		result.map {|doc| doc[:_id].to_s}
		
	end
	
	def self.create_indexes
		self.collection.indexes.create_one("geometry.geolocation" => Mongo::Index::GEO2DSPHERE)
	end
	
	def self.remove_indexes
		self.collection.indexes.drop_one("geometry.geolocation_2dsphere")
	end
	
	def self.near (point, max_meters = nil)
		near_query={:$geometry=>point.to_hash}
	    near_query[:$maxDistance]=max_meters if !max_meters.nil?
	    collection.find(:'geometry.geolocation'=>{:$near=>near_query})
	end
	
	def near( max_dist = nil)
		
	  self.class.to_places(self.class.near(@location, max_dist))
	 	
	 	
	end
	
	

	def self.to_places(coll)
	    result=[]
	    coll.map do |place|
	   		result << Place.new(place)
	   	end
	   	result
  	end
end