require 'uri'
require 'hallon'

module Mumbletune

	class SpotifyTrack < Track
		def initialize(params)
			super

			@uri = params[:uri]
			@url = SPURIServer.url_for(@uri)
		end

		def self.track_from_uri(uri)
			track = MetaSpotify::Track.lookup(uri)

			# force track to be playable within region
			unless track.album.available_territories.include? Mumbletune.config["spotify"]["region"]
				raise "#{track.name}: Not available in this region."
			end

			song = SpotifyTrack.new({
				:name => track.name,
				:artist => track.artists.first.name,
				:album => track.album.name,
				:uri => track.uri
			})

			song = Hallon::Track.new(uri)
			song.load

			# Technically, a collection of one.
			Collection.new(
				:TRACK,
				song,
				"<b>#{song.name}</b> by <b>#{song.artist.name}</b>"
				)
		end

		def self.tracks_from_album(uri)	
			album = MetaSpotify::Track.lookup(uri)

			# force album to be playable in region
			unless album.available_territories.include? Mumbletune.config["spotify"]["region"]
				raise "#{album.name}: Not available in this region."
			end

			album = Hallon::Album.new(uri)
			album.load
			browse = album.browse
			browse.load

			Collection.new(
				:ALBUM,
				browse.tracks,
				"the album <b>#{album.name}</b> by <b>#{album.artist.name}</b>"
				)
		end

		def self.tracks_from_artist(uri)
			artist = Hallon::Artist.new(uri)
			artist.load

			tracks_needed = Mumbletune.config["mumbletune"]["tracks_for_artist"] || 5

			search = Hallon::Search.new("artist:\"#{artist.name}\"", tracks: tracks_needed)

			Collection.new(
				:ARTIST_TOP,
				search.tracks,
				"#{search.tracks.length} tracks by <b>#{artist.name}</b>"
				)
		end
	end
end