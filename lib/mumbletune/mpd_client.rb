require 'ruby-mpd'

module Mumbletune

	class Player

		attr_accessor :history

		def initialize(host=Mumbletune.config['mpd']['host'], port=Mumbletune.config['mpd']['port'])
			@mpd = MPD.new(host, port)
			@mpd.connect true # 'true' enables callbacks
			@mpd.clear

			@history = Array.new
			@prev_id = 0

			self.default_volume
			self.establish_callbacks
		end

		# Setup

		def default_volume
			@mpd.volume = Mumbletune.config["mpd"]["default_volume"] || 100
		end

		def establish_callbacks
			@mpd.on :connection do |status|
				if status == false
					@mpd.connect true
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
			# associate known Tracks with Queue items
			mapped_queue = @mpd.queue.map do |mpd_song|
				t = Track.retreive_from_mpd_id(mpd_song.id)
				t.queue_pos = mpd_song.pos
				t
			end
			# mapped_queue.delete_if { |t| t == current_song }
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

		
=begin 
		# Deprecated add methods. Time to remove?

		def add(track)
			id = @mpd.addid track.url
			track.mpd_id = id
		end

		def add_batch(tracks)
			tracks.each do |t|
				id = @mpd.addid t.url
				t.mpd_id = id
			end
		end

		def add_now(track)
			id = @mpd.addid track.url, 1
			track.mpd_id = id
			@mpd.next
		end

		def add_now_batch(tracks)
			tracks.each do |t|
				id = @mpd.addid t.url, tracks.index(t)+1
				t.mpd_id = id
			end
			@mpd.next
		end
=end

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