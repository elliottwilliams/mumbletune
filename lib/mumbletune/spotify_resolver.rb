require "hallon"

module Mumbletune
	class SpotifyResolver
		def self.track(track)
			track.load

			raise "#{track.name}: Not available in this region." unless track.available?

			# Technically, a collection of one.
			Collection.new(
				:TRACK,
				track,
				"<b>#{track.name}</b> by <b>#{track.artist.name}</b>"
				)
		end

		def self.tracks_from_album(album)	
			album.load

			raise "#{album.name}: Not available in this region." unless album.available?

			browse = album.browse
			browse.load

			Collection.new(
				:ALBUM,
				browse.tracks.to_a,
				"the album <b>#{album.name}</b> by <b>#{album.artist.name}</b>"
				)
		end

		def self.tracks_from_artist(artist)
			artist.load

			tracks_needed = Mumbletune.config["player"]["tracks_for_artist"] || 5

			search = Hallon::Search.new("artist:\"#{artist.name}\"",
				tracks: tracks_needed,
				artists: 0,
				albums: 0,
				playlists: 0).load

			Collection.new(
				:ARTIST_TOP,
				search.tracks.to_a,
				"#{search.tracks.size} tracks by <b>#{artist.name}</b>"
				)
		end
	end
end