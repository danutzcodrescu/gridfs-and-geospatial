class Point

	attr_accessor :latitude, :longitude

	def initialize(params={})
  		 if !params[:longitude] && !params[:latitude]
	      @longitude=params[:coordinates][0]
	      @latitude=params[:coordinates][1]
	    else 
	      @longitude=params[:lng]
	      @latitude=params[:lat]
	    end


	end

	def to_hash
		{:type=>"Point", :coordinates=> [ @longitude, @latitude]}
	end
end