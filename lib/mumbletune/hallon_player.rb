require "hallon"
require "hallon-queue-output"
require "thread"

module Mumbletune

	class HallonPlayer

		attr_accessor :ready, :history, :queue, :current_track, :audio_queue

		def initialize
			conf = Mumbletune.config

			@history = Array.new
			@queue   = Array.new
			@prev_id = 0
			@ready = false
			@audio_queue = Queue.new
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

			# play it, if this is the first track or if the user specified `now`
			self.next if now || only_track
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
			@history << @queue.shift if @queue.first && @queue.first.empty?

			return stop unless any?

			track = @queue.first.next

			return stop unless track

			# play that shit!
			@current_track = track
			@player.play track

			puts "\u266B  #{track.name} - #{track.artist.name}"
			Mumbletune.access_log.info "\u266B  #{track.name} - #{track.artist.name}"
		end

		def stop
			@player.stop
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