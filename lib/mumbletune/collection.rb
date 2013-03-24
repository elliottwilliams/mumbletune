module Mumbletune
	class Collection
		attr_accessor :type, :tracks, :description, :user

		def initialize(type, tracks, description)
			@type = type
			@description = description

			if tracks.class == Array
				@tracks = tracks
			else
				@tracks = [tracks]
			end
		end

		def user=(username)
			@user = username
			@tracks.each { |t| t.username = username }
		end
	end
end