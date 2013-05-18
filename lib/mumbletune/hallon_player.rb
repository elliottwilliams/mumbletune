require "hallon"
require "hallon-queue-output"
require "thread"

module Mumbletune

	class HallonPlayer

		attr_accessor :ready, :play_history, :add_history, :queue, :current_track, :audio_queue

		def initialize
			conf = Mumbletune.config

			@play_history = Array.new
			@add_history  = Array.new
			@queue        = Array.new
			@prev_id      = 0
			@ready        = false
			@audio_queue  = Queue.new

			@ready = true
		end

		def connect
			conf = Mumbletune.config

			@session = Hallon::Session.initialize(IO.read(conf["spotify"]["appkey"]))
			@session.login!(conf["spotify"]["username"], conf["spotify"]["password"])

			@player = Hallon::Player.new(Hallon::QueueOutput) do
				# Set driver options
				@driver.queue = Mumbletune.player.audio_queue
				@driver.verbose = true if Mumbletune.verbose

				# Define callbacks
				on(:end_of_track) { Mumbletune.player.next }
				on(:streaming_error) { |s, e| raise "Spotify connection error: #{e}" }
				on(:play_token_lost) { Mumbletune.player.play_token_lost }
			end

			@ready = true

			start_event_loop
		end

		def disconnect
			@logging_out = true
			@event_loop_thread.kill
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

		def any?
			cols_with_more = @queue.map { |col| col.any? }
			cols_with_more.delete_if { |m| m == false }
			cols_with_more.any?
		end

		def empty?
			!any?
		end

		# Queue Control
		def add_collection(col, now=false)
			only_track = empty?

			# add to the queue
			if now
				@queue.unshift col
			else
				@queue.push col
			end

			# record in additions history
			@add_history.push col

			# play it, if this is the first track or if the user specified `now`
			self.next if now || only_track
		end

		def undo
			removed = @add_history.pop
			@queue.delete_if { |col| col == removed }
			self.next if removed.current_track
			removed
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
			# move the collection to play_history if it has played all its tracks
			@play_history << @queue.shift if @queue.first && @queue.first.empty?

			return stop unless any?

			track = @queue.first.next

			return stop unless track

			# play that shit!
			@current_track = track
			@player.play track

			puts "\u266B  #{track.name} - #{track.artist.name}" unless Mumbletune.verbose
		end

		def stop
			@player.stop
		end

		# Callback Handling
		def play_token_lost
			Mumbletune.mumble.broadcast %w{Mumbletune was just paused because this
				Spotify account is being used elsewhere. Type <code>unpause
				</code> to regain control and keep playing.} * " "
		end

		private

		def start_event_loop
			@event_loop_thread = Thread.new do
				loop do
					@session.process_events unless @session.disconnected?
					sleep 1
				end
			end
		end
		
	end
end