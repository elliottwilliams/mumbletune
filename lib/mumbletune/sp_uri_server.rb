# NOT USED at the moment, since we wrote for Hallon after spotify-websocket-api
#   started having problems.

require 'sinatra/base'

module Mumbletune

	module SPURIServer

		class Server < Sinatra::Base
			set :run, true
			set :server, :thin
			set :logging, false
			set :app_file, __FILE__
			set :bind, 'localhost'
			set :port, 8081

			get '/play/:uri' do
				cred = Mumbletune.config['spotify']
				sp = Mumbletune::Spotify.new(cred['username'], cred['password'])

				track = sp.objectFromURI(params[:uri])
				halt 404, "Could not find a track with that URI." if track == nil

				url = track.getFileURL().to_s
				halt 404, "Could not find a track URL for that URI." if track == nil

				sp.logout
				redirect url, 303
			end
		end

		def self.url_for(uri)
			bind = Server::bind
			port = Server::port
			"http://#{bind}:#{port}/play/#{uri}"
		end

		def self.sp_uri_for(url)
			regexp = /(.+)(<sp_uri>spotify:\w+:\w+)/i
			matched = regexp.match(url)
			matched[:sp_uri]
		end
	end
end