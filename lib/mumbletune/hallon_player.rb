require "hallon"
require "hallon-fifo"

module Mumbletune

	class HallonPlayer

		attr_accessor :history, :queue, :current_song

		def initialize
			conf = Mumbletune.config

			@history, @queue = Array.new
			@prev_id = 0

			@player = Hallon::Player.new(Hallon::Fifo) do
				# Set driver options
				@driver.output = conf["player"]["fifo_out"]

				# Define callbacks
				on(:end_of_track) { play_next }
				on(:connection_error) { |s, e| raise "Spotify connection error: #{e}" }
			end
		end

		def connect
			@session = Hallon::Session.initialize(IO.read(conf["spotify"]["appkey"]))
			@session.login!(conf["spotify"]["username"], conf["spotify"]["password"])
			puts ">> Connected to Spotify"
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

		# Queue Control
		def add_collection(col, now=false)
			# add to the queue
			if now
				@queue.unshift col
			else
				@queue.push col
			end

			# add to history
			@history.push col

			# play it, if the user's being impatient
			next if now
		end

		def undo
			last_collection  = @history.pop

			last_collection.tracks.each do |t|
				@queue.delete_if { |q_t| t == q_t }
			end
		end

		def clear_queue
			@queue.clear
		end

		# Playback Commands
		def play
			if stopped?
				next
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
			track = @queue.first.next

			# delete the collection if it has played all its tracks
			@queue.shift if @queue.first.length < 1

			# play that shit!
			@current_song = track
			@player.play track
		end

		def stop
			@player.stop
		end


	end
end