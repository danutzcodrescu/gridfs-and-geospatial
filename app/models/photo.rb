class Photo

    attr_accessor :id, :location
    attr_writer :contents
    
    
    def self.mongo_client
		Mongoid::Clients.default
	end
	
	def initialize(params={})

    	     if params[:metadata]
    	         @id=params[:_id].to_s if !params[:_id].nil? 
    	         @location =  Point.new(params[:metadata][:location]) if !params[:metadata].nil? 
    	         @place = params[:metadata][:place] if !params[:metadata].nil? 
    	    else   
    	         @id=params[:_id].to_s if !params[:_id].nil? 
    	         @location =  Point.new(params[:location]) if !params[:location].nil?
    	         @place = params[:place] if !params[:place].nil?
    	    end
    	
	end
	
    def persisted?
        !@id.nil?
    end
	
	def save
        if !persisted?
            gps=EXIFR::JPEG.new(@contents).gps
            @location = Point.new(:lng=>gps.longitude, :lat=>gps.latitude)
            metadata = {}
            metadata[:location] = @location.to_hash if @location
            metadata[:place] = @place  if @place
            @contents.rewind
            descr={}
            descr[ :content_type] = "image/jpeg"
            descr[:metadata] = metadata
            grid = Mongo::Grid::File.new(@contents.read,descr)
            @id=self.class.mongo_client.database.fs.insert_one(grid).to_s
        else
            metadata={}
            metadata[:location] = @location.to_hash if @location
            if @place
                if @place.is_a? String
                    metadata[:place]=BSON::ObjectId.from_string(@place.to_s)
                elsif @place.is_a? Place 
                    metadata[:place]=@place.id
                else
                    metadata[:place]=@place
                end
            end
 
            self.class.mongo_client.database.fs.find({:_id=>BSON::ObjectId.from_string(@id.to_s)}).update_one(metadata)
        end
    end
    
    def self.all (skip=0, limit=nil)
        
        result= self.mongo_client.database.fs.find().skip(skip)
        result=result.limit(limit) if !limit.nil?
       
        if result.nil?
            return nil
        else
            result.map do |photo|
  
                Photo.new(photo)
            end
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
	
    def contents
        data=self.class.mongo_client.database.fs.find_one({_id: BSON::ObjectId.from_string(@id)})
         if data 
            buffer = ""
            data.chunks.reduce([]) do |x,chunk| 
                buffer << chunk.data.data 
            end
            return buffer
        end 
    end
	
	def place=(id)
		if place.is_a? String
            @place = BSON::ObjectId.from_string(id)
        else
            @place = id
        end
	end
	
	def place
  		Place.find(@place.to_s) if !@place.nil?
	end
	
	def self.find_photos_for_place(id)
	    self.mongo_client.database.fs.find(:place => id)
	end
	
	
end    