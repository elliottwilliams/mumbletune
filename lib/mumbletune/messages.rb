require 'uri'
require 'text'
require 'mustache'

Thread.abort_on_exception=true # development only

module Mumbletune

	class Message

		# class methods

		class << self
			attr_accessor :template
		end
		self.template = Hash.new

		def self.parse(client, data)
			message = Message.new(client, data)

			begin
				case message.text

				when /^play/i
					if message.argument.length > 0 # user wants to play something
						if message.words.last =~ /now/i
							play_now = true 
							message.argument = message.words[1...message.words.length-1].join(" ")
						else
							play_now = false
						end

						# reassurance that it's working
						message.respond "I'm searching. Hang tight."
						
						collection = Mumbletune.resolve(message.argument)

						# handle unknown argument
						return message.respond "I couldn't find what you wanted me to play. :'(" unless collection

						# associate the collection with a user
						collection.user = message.sender.name

						# add these tracks to the queue
						Mumbletune.player.add_collection collection, (play_now) ? true : false

						if play_now
							message.respond_all "#{message.sender.name} is playing #{collection.description} RIGHT NOW."
						else
							message.respond_all "#{message.sender.name} added #{collection.description} to the queue."
						end

						Mumbletune.player.play unless Mumbletune.player.playing?

						
					else # user wants to unpause
						if Mumbletune.player.paused?
							Mumbletune.player.play
							message.respond "Unpaused."
						else
							message.respond "Not paused."
						end
					end

				when /^pause$/i
					paused = Mumbletune.player.pause
					response = (paused) ? "Paused." : "Unpaused."
					message.respond response

				when /^unpause$/i
					if Mumbletune.player.paused?
						Mumbletune.player.play
						message.respond "Unpaused."
					else
						message.respond "Not paused."
					end


				when /^next$/i
					Mumbletune.player.next
					current = Mumbletune.player.current_song
					message.respond_all "#{message.sender.name} skipped to #{current.artist} - #{current.name}"

				when /^clear$/i
					Mumbletune.player.clear_queue
					message.respond_all "#{message.sender.name} cleared the queue."

				when /^undo$/i
					removed = Mumbletune.player.undo
					if message.sender.name == removed.user
						message.respond_all "#{message.sender.name} removed #{removed.description}."
					else 
						message.respond_all "#{message.sender.name} removed #{removed.description} at #{removed.user} added."
					end


				when /^(what|queue)$/i
					queue = Mumbletune.player.queue

					# Now, a template.
					rendered = Mustache.render Message.template[:queue],
						:queue => queue,
						:anything? => (queue.empty?) ? false : true
					message.respond rendered

				when /^volume\?$/i
					message.respond "The volume is #{Mumbletune.player.volume?}."

				when /^volume/i
					if message.argument.length == 0
						message.respond "The volume is #{Mumbletune.player.volume?}."
					else
						Mumbletune.player.volume(message.argument)
						message.respond "Now the volume is #{Mumbletune.player.volume?}."
					end

				when /^help$/i
					rendered = Mustache.render Message.template[:commands]
					message.respond rendered

				else # Unknown command was given.
					rendered = Mustache.render Message.template[:commands],
						:unknown => { :command => message.text }
					message.respond rendered
				end

			rescue => err # Catch any command that errored.
				message.respond "Woah, an error occurred: #{err.message}"
				puts "#{err.class}: #{err.message}"
				puts err.backtrace
			end
		end


		# instance methods

		attr_accessor :client, :sender, :text, :command, :argument, :words

		def initialize(client, data)
			@client = client
			@sender = client.users[data[:actor]] # users are stored by their session ID
			@me = client.me
			@text = data[:message]

			@words = @text.split
			@command = words[0]
			@argument = words[1...words.length].join(" ")
		end

		def respond(message)
			@client.text_user(@sender.session, message)
		end

		def respond_all(message) # send to entire channel
			@client.text_channel(@me.channel_id, message)
		end
	end

	# load templates
	Dir.glob(File.dirname(__FILE__) + "/templates/*.mustache").each do |f_path|
		f = File.open(f_path)
		Message.template[File.basename(f_path, ".mustache").to_sym] = f.read
	end
end