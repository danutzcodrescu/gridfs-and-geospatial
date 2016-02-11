class Photo

    attr_accessor :id, :location
    attr_reader :contents
    attr_writer :contents
    
    
    def self.mongo_client
		Mongoid::Clients.default
	end
	
	def initialize(params={})
	    if params[:_id] && params[:metadata][:location]
	         @id=params[:_id].to_s
	         @location =  Point.new(params[:metadata][:location])
	    end
	end
	
	def persisted?
	    !@id.nil?
	end
	
	def save
        if !persisted?
            gps=EXIFR::JPEG.new(@contents).gps
            @location = Point.new(:lng=>gps.longitude, :lat=>gps.latitude)
            descr={}
            descr[ :content_type] = "image/jpeg"
            metadata = {}
            metadata[:location] = @location.to_hash if @location
            metadata[:place] = @place  if @place
            descr[:metadata] = metadata
            grid = Mongo::Grid::File.new(@contents.read,descr)
            @id=self.class.mongo_client.database.fs.insert_one(grid).to_s
        else
            updates={}
            metadata[:location] = @location.to_hash
            updates[:metadata]=metadata
            self.class.mongo_client.database.fs.find({:_id=>BSON::ObjectId.from_string(@id.to_s)}).update_one(:$set => updates)
            
        end
    end
    
    def self.all (skip=0, limit=nil)
        result= self.mongo_client.database.fs.find().skip(skip)
        result=result.limit(limit) if !limit.nil?
        result.map do |doc| 
            Photo.new(doc)
        end
    end
    
    def self.find (id)
        result = self.mongo_client.database.fs.find({:_id=>BSON::ObjectId.from_string(id.to_s)}).first
        if result.nil?
            return nil
        else
            @id = result[:_id].to_s
            @location = result[:location]
            Photo.new(result)
        end
    end
    
    def destroy
		self.class.mongo_client.database.fs.find({_id: BSON::ObjectId.from_string(@id)}).delete_one
	end
	
	def find_nearest_place_id (max)
		result = Place.near(@location,max).limit(1).projection(_id:1).first[:_id]
	end
end    