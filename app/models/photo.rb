class Photo

    attr_accessor :id, :location, :contents
    
    
    def self.mongo_client
		Mongoid::Clients.default
	end
	
	def initialize(params={})
	    if params[:_id]
	         @id=params[:_id].to_s
	         @location = params[:metadata][:location].nil ? nil : Point.new(params[:metadata][:location])
	   
	    end
	end
	
	def persisted?
	    !@id.nil?
	end
	
	def save
        if !persisted?
            descr={}
            descr[ :content_type] = "image/jpeg"
            metadata = {}
            metadata[:location] = @location.to_hash if @location
            metadata[:place] = @place if @place
            descr[:metadata] = metadata
            grid = Mongo::Grid::File.new(@contents.read,descr)
            @id=self.class.mongo_client.database.fs.insert_one(grid).to_s
        end
    end
  
end