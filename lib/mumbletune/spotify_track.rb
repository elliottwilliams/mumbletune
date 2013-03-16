require 'uri'

module Mumbletune

	class SpotifyTrack < Track
		def initialize(params)
			super

			@uri = params[:uri]
			@url = SPURIServer.url_for(@uri)
		end

		def self.track_from_uri(track)
			track = MetaSpotify::Track.lookup(track) unless track.class == MetaSpotify::Track

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

			# Technically, a collection of one.
			Collection.new(
				:TRACK,
				song,
				"<b>#{song.name}</b> by <b>#{song.artist}</b>"
				)
		end

		def self.tracks_from_album(album_ref)	
			album_uri = album_ref.uri if album_ref.class == MetaSpotify::Album
			album = MetaSpotify::Album.lookup(album_uri, {:extras => "track"})

			# force album to be playable in region
			unless album.available_territories.include? Mumbletune.config["spotify"]["region"]
				raise "#{album.name}: Not available in this region."
			end

			tracks = []
			album.tracks.each do |track|
				tracks.push SpotifyTrack.new({
					:name => track.name,
					:artist => track.artists.first.name,
					:album => album.name,
					:uri => track.uri
				})
			end

			Collection.new(
				:ALBUM,
				tracks,
				"the album <b>#{album.name}</b> by <b>#{album.artists.first.name}</b>"
				)
		end

		def self.tracks_from_artist(artist)
			artist = MetaSpotify::Artist.lookup(artist) unless artist.class == MetaSpotify::Artist

			# spotify metadata api still error-prone
			search_result = Mumbletune.handle_sp_error { MetaSpotify::Track.search("artist:\"#{artist.name}\"") }

			# filter out tracks outside region
			search_result[:tracks].select! do |track|
				track.album.available_territories.include? Mumbletune.config["spotify"]["region"]
			end

			tracks = []
			search_result[:tracks][0...10].each do |track|
				tracks.push SpotifyTrack.new({
					:name => track.name,
					:artist => track.artists.first.name,
					:album => track.album.name,
					:uri => track.uri
				})
			end

			Collection.new(
				:ARTIST_TOP,
				tracks,
				"#{tracks.length} tracks by <b>#{artist.name}</b>"
				)
		end
	end
end