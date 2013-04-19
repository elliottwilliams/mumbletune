require 'uri'
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
					obj = Hallon::Track.new(sp_uri)
					SpotifyResolver.track(obj)
				when "album" # Return all tracks of the album to queue
					obj = Hallon::Album.new(sp_uri)
					SpotifyResolver.tracks_from_album(obj)
				when "artist" # Return 10 tracks for this artist
					obj = Hallon::Artist.new(sp_uri)
					SpotifyResolver.tracks_from_artist(obj)
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
				search = Hallon::Search.new(query, artists: 1, albums: 1, tracks: 1).load
				if first_word =~ /^artist$/i
					result = search.artists.first

				elsif first_word =~ /^album$/i
					result = search.albums.first

				elsif first_word =~ /^track$/i
					result = search.tracks.first

				else # determine intended result by similarity to the query
					compare = []
					compare.push search.tracks.first if search.tracks.any?
					compare.push search.albums.first if search.albums.any?
					compare.push search.artists.first if search.artists.any?
					
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

				if result.class == Hallon::Artist
					SpotifyResolver.tracks_from_artist(result)
				elsif result.class == Hallon::Album
					SpotifyResolver.tracks_from_album(result)
				elsif result.class == Hallon::Track
					SpotifyResolver.track(result)
				end

			end
		end
	end
end