require "hallon"
require "hallon-fifo"

module Mumbletune

	class HallonPlayer

		attr_accessor :ready, :history, :queue, :current_track

		def initialize
			conf = Mumbletune.config

			@history = Array.new
			@queue   = Array.new
			@prev_id = 0
			@ready = false

			connect

			@player = Hallon::Player.new(Hallon::Fifo) do
				# Set driver options
				@driver.output = conf["player"]["fifo"]["path"]

				# Define callbacks
				on(:end_of_track) { puts "Playing next..."; self.next }
				on(:streaming_error) { |s, e| raise "Spotify connection error: #{e}" }
			end

			@ready = true
		end

		def connect
			conf = Mumbletune.config

			@session = Hallon::Session.initialize(IO.read(conf["spotify"]["appkey"]))
			@session.login!(conf["spotify"]["username"], conf["spotify"]["password"])
		end

		def disconnect
			@logging_out = true
			@session.logout!
		end

		# Status methods
		def playing?
			@player.status == :playing
		end

		def paused?
			@player.status == :paused
		end

		def stopped?
			@player.status == :stopped
		end

		def more?
			cols_with_more = @queue.map { |col| col.more? }
			cols_with_more.delete_if { |m| m == false }
			cols_with_more.any?
		end

		# Queue Control
		def add_collection(col, now=false)
			# add to the queue
			if now
				@queue.unshift col
			else
				@queue.push col
			end

			# play it, if we're starting playback or if the user's wants it now
			self.next if now || stopped?
		end

		def undo
			@queue.pop
		end

		def clear_queue
			@queue.clear
			self.stop
		end

		# Playback Commands
		def play
			if stopped?
				self.next
			elsif paused?
				@player.play
			end
		end

		def pause
			if playing?
				@player.pause
			elsif paused?
				@player.play
			end
		end

		def next
			# move the collection to history if it has played all its tracks
			@history << @queue.shift if @queue.first.done?

			track = @queue.first.next

			# play that shit!
			@current_track = track
			@player.play track

			puts "\u266B  #{track.name} - #{track.artist.name}"
		end

		def stop
			@player.stop
		end


	end
end