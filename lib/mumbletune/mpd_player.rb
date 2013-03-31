require 'ruby-mpd'

module Mumbletune

	class MPDPlayer

		attr_accessor :history

		def initialize(host=Mumbletune.config["player"]['host'], port=Mumbletune.config["player"]['port'])
			@mpd = MPD.new(host, port)
			self.connect
			self.clear_all

			@history = Array.new
			@prev_id = 0

			self.defaults
			self.establish_callbacks
		end

		def connect
			@disconnecting = false
			@mpd.connect true # 'true' enables callbacks
		end

		def disconnect
			@disconnecting = true
			@mpd.disconnect
			puts ">> Disconnected from MPD"
		end

		# Setup

		def defaults
			@mpd.volume = Mumbletune.config["player"]["default_volume"] || 100
			@mpd.consume = true
		end

		def establish_callbacks
			@mpd.on :connection do |status|
				if status == false && !@disconnecting
					self.connect
				else
					puts ">> MPD happens to be connected."
				end
			end

			# Fires when currently playing song changes.
			@mpd.on :songid do |id|
				
				# Clear old tracks from the store.
				Track.store.delete_if { |t| t.mpd_id == @prev_id }

				@prev_id = id
			end
		end

		# Status methods

		def playing?
			state = @mpd.status[:state]
			if state =~ /^(play|pause)$/i
				true
			else
				false
			end
		end

		def paused?
			state = @mpd.status[:state]
			if state == :pause
				true
			else
				false
			end
		end


		# MPD Settings

		def volume?
			@mpd.volume
		end

		def volume(percent)
			@mpd.volume = percent
		end



		# Queue

		def add_collection(col, now=false)
			col.tracks.each do |t|
				id = @mpd.addid t.url,
					 (now) ? col.tracks.index(t)+1 : nil
				t.mpd_id = id
			end

			@history.push col

			@mpd.next if now
		end

		def queue
			# Combine the future queue with the current track.
			#   MPD puts the current track in its queue only if
			#   other tracks are queued to play. Account for this.
			queue = @mpd.queue
			queue.unshift @mpd.current_song if @mpd.current_song

			# Delete index 0 if first queue position and current song are duplicates.
			queue.delete_at(0) if queue[1] && queue[0] == queue[1]

			# Associate known Tracks with Queue items.
			mapped_queue = queue.map do |mpd_song|
				t = Track.retreive_from_mpd_id(mpd_song.id)
				if t
					t.queue_pos = mpd_song.pos
					t
				end
			end
			mapped_queue
		end

		def current_song
			Track.retreive_from_mpd_id(@mpd.current_song.id) if @mpd.playing?
		end

		def undo
			last_collection = @history.pop

			last_collection.tracks.each do |t|
				to_delete = @mpd.queue.select { |mpd_song| mpd_song.id == t.mpd_id }.first
				@mpd.delete(to_delete.pos) if to_delete
			end
			last_collection
		end

		def clear_all
			@mpd.clear
		end

		def clear_queue
			current = @mpd.current_song
			@mpd.queue.each do |t|
				@mpd.delete :id => t.id unless t.id == current.id
			end
		end

		# Playback commands

		def play
			@mpd.play
		end

		def pause
			@mpd.pause = (@mpd.playing?) ? true : false
		end

		def next
			@mpd.next
		end

		def stop
			@mpd.stop
		end

	end

end