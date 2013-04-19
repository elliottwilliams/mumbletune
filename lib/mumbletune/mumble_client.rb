require 'mumble-ruby'

module Mumbletune
	class MumbleClient

		def initialize
			m_conf = Mumbletune.config["mumble"]
			f_conf = Mumbletune.config["player"]["fifo"]
			format = {rate: f_conf["sample_rate"], channels: f_conf["channels"], vbr_rate: f_conf["vbr_rate"]}
			@cli = Mumble::Client.new(m_conf['host'], m_conf['port'], m_conf['username'], m_conf['password'], format)

			@cli.on_server_sync do |message| # Once connected.
				@cli.session = message.session # housekeeping for mumble-ruby
				connect_to = @cli.channels.select { |key, hash| hash["name"] == m_conf["channel"] }.first[1][:name]
				@cli.join_channel connect_to

				@ready = true
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
			input = Mumbletune.config["player"]["fifo"]["path"]
			Thread.current.priority = 5
			@audio_stream = @cli.stream_raw_audio(input)
			self.volume = Mumbletune.config["player"]["default_volume"]
		end

		def disconnect
			@audio_stream.stop if @audio_stream
			@cli.disconnect
		end

		def volume
			(@audio_stream.volume * 100).to_i
		end

		def volume=(vol)
			@audio_stream.volume = vol.to_i
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