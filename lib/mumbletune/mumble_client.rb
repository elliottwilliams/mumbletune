require 'mumble-ruby'

module Mumbletune
	class MumbleClient

		def initialize
			opts = Mumbletune.config['mumble']
			@cli = Mumble::Client.new(opts['host'], opts['port'], opts['username'], opts['password'])

			@cli.on_server_sync do |message| # Once connected.
				@cli.session = message.session # housekeeping for mumble-ruby
				connect_to = @cli.channels.select { |key, hash| hash["name"] == opts['channel'] }.first[1][:name]
				@cli.join_channel(connect_to)

				@ready = true
				puts ">> Connected to Mumble server at #{opts['host']}."
			end

			@cli.on_text_message do |data|
				if data[:session].include?(@cli.me[:session]) # if message was sent to us
					# interpret the message in a separate thread
					Thread.new { Message.parse(@cli, data) }
				end
			end
		end

		def connect
			@ready = false
			@cli.connect

			@ready_wait = Thread.new do 
				sleep 0.1 until @ready
			end
		end

		def stream
			@ready_wait.join
			input = Mumbletune.config["player"]["fifo_out"]
			Thread.current.priority = 5
			puts ">> Streaming to Mumble from #{input}"
			@cli.stream_raw_audio(input)
		end

		def disconnect
			@cli.disconnect
			puts ">> Disconnected from Mumble"
		end
	end

end

# on_server_sync is used internally, and our callback overloads its own.
#   We need access to `session` to handle the function internally
module Mumble
	class Client
		attr_accessor :session
	end
end