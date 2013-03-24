module Mumbletune
	class Track
		attr_accessor :name, :artist, :album, :url, :username, :mpd_id, :queue_pos

		class << self
			attr_accessor :store
		end
		self.store = []

		def initialize(params)
			@name = params[:name]
			@artist = params[:artist]
			@album = params[:album]
			@url = params[:url]

			Track.store.push self
		end

		def playing?
			if self == Mumbletune.player.current_song
				true
			else
				false
			end
		end

		def self.retreive_from_mpd_id(id)
			Track.store.select { |t| t.mpd_id == id }.first
		end

	end
end