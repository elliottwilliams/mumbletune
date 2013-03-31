require 'uri'
require 'meta-spotify'
require 'text'


module Mumbletune
	def self.resolve(argument)
		Resolvers.workers.each do |r|
			if r.matches?(argument)
				return r.resolve(argument)
			end
		end
		return false
	end

	module Resolvers
		class << self
			attr_accessor :workers
		end

		@workers = []

		class Resolver
			def matches?(arg); end
			def resolve(arg); end
			def self.inherited(subcl)
				Resolvers.workers.push(subcl.new)
			end
		end

		class SpotifyURIResolver < Resolver
			def matches?(uri)
				http_uris = URI.extract(uri, ['http', 'https'])
				sp_uris = URI.extract(uri, 'spotify')
				if http_uris.any?
					parsed_uri = URI.parse(http_uris.join)
					if parsed_uri.hostname =~ /(?:open|play)\.spotify\.com/i
						true
					else
						false
					end
				elsif sp_uris.any?
					true
				else
					false
				end
			end
			def resolve(uri)
				raise "Not a Spotify URI." unless matches?(uri)
				regexp = /(?<type>track|artist|album)[\/|:](?<id>\w+)/i
				matched = regexp.match(uri)
				type = matched[:type]
				id = matched[:id]
				sp_uri = "spotify:#{type}:#{id}"

				# behave according to URI type
				case type
				when "track" # Return this track
					SpotifyTrack::track_from_uri(sp_uri.uri)
				when "album" # Return all tracks of the album to queue
					SpotifyTrack::tracks_from_album(sp_uri.uri)
				when "artist" # Return 10 tracks for this artist
					SpotifyTrack::tracks_from_artist(sp_uri.uri)
				end
			end
		end

		class SpotifySearchResolver < Resolver
			def matches?(query)
				# basically we will search for anything that's not a URL
				if URI.extract(query).any?
					return false
				else
					return true
				end
			end
			def resolve(query)
				first_word = query.split.first

				# if first word is a type to search for, it needs to be stripped
				#    from the query so we don't search for it (e.g. "track starships")
				if first_word =~ /^(artist|album|track)$/i
					query_a = query.split
					query_a.delete_at 0
					query = query_a.join(" ")
				end

				# used to check if tracks are playable in in region
				region = Mumbletune.config["spotify"]["region"]

				# determine result based on a type in the first word
				if first_word =~ /^artist$/i
					artist = Mumbletune.handle_sp_error { MetaSpotify::Artist.search(query) }
					result = artist[:artists].first

				elsif first_word =~ /^album$/i
					album = Mumbletune.handle_sp_error { MetaSpotify::Album.search(query) }
					album[:albums].select! { |a| a.available_territories.include? region }
					result = album[:albums].first

				elsif first_word =~ /^track$/i
					track = Mumbletune.handle_sp_error { MetaSpotify::Track.search(query) }
					track[:tracks].select! { |t| t.album.available_territories.include? region }
					result = track[:tracks].first

				else # determine intended result by similarity to the query
					artist = Mumbletune.handle_sp_error { MetaSpotify::Artist.search(query) }
					album = Mumbletune.handle_sp_error { MetaSpotify::Album.search(query) }
					track = Mumbletune.handle_sp_error { MetaSpotify::Track.search(query) }

					# searches now finished

					# remove anything out-of-region
					album[:albums].select! { |a| a.available_territories.include? region } if album[:albums].any?
					track[:tracks].select! { |t| t.album.available_territories.include? region } if track[:tracks].any?

					compare = []
					compare.push track[:tracks].first if track[:tracks].any?
					compare.push album[:albums].first if album[:albums].any?
					compare.push artist[:artists].first if artist[:artists].any?
					
					white = Text::WhiteSimilarity.new
					compare.sort! do |a, b|
						a_sim = white.similarity(query, a.name)
						b_sim = white.similarity(query, b.name)
						if a_sim > b_sim
							-1
						elsif b_sim > a_sim
							1
						else
							0
						end
					end
					result = compare.first
				end

				if result.class == MetaSpotify::Artist
					SpotifyTrack.tracks_from_artist(result.uri)
				elsif result.class == MetaSpotify::Album
					SpotifyTrack.tracks_from_album(result.uri)
				elsif result.class == MetaSpotify::Track
					SpotifyTrack.track_from_uri(result.uri)
				end

			end
		end
	end
end