require 'bundler/setup'

require 'mumbletune/version'
require 'mumbletune/mumble_client'
require 'mumbletune/hallon_player'
require 'mumbletune/messages'
require 'mumbletune/collection'
require 'mumbletune/resolver'
require 'mumbletune/spotify_resolver'

require 'optparse'
require 'yaml'

module Mumbletune
	class << self
		attr_reader :player, :mumble, :uri_server, :config, :verbose
	end

	# defaults
	@verbose 		= false
	config_file 	= nil

	# parse command line options
	opts = OptionParser.new do |opts|
		opts.banner = "Usage: mumbletune.rb [options]"
		opts.on("-c", "--config FILE", "=MANDATORY", "Path to configuration file") do |file|
			config_file = file
		end
		opts.on("-v", "--verbose", "Verbose output") do
			@verbose = true
		end
		opts.on("-h", "--help", "This help message") do
			puts opts.help
			exit
		end
	end

	opts.parse!

	unless config_file
		puts opts.help
		exit
	end

	# load configuration file
	@config = YAML.load_file(config_file)

	# initialize player
	play_thread = Thread.new do
		@player = HallonPlayer.new
		@player.connect
		puts ">> Connected to Spotify."
	end

	# connect to mumble & start streaming
	sleep 0.1 until @player && @player.ready
	mumble_thread = Thread.new do
		@mumble = MumbleClient.new
		@mumble.connect
		puts ">> Connected to Mumble server at #{self.config['mumble']['host']}."
		@mumble.stream
	end

	# shutdown code
	def self.shutdown
		Thread.new do
			sleep 5 # timeout
			puts "Timeout. Forcing exit."
			exit!
		end
		print "\n>> Exiting... "
		self.mumble.disconnect
		print "Disconnected from Mumble... "
		self.player.disconnect
		print "Disconnected from Spotify... "
		puts "\nGoodbye forever."
	 	exit
	end

	# exit when Ctrl-C pressed
	Signal.trap("INT") do
		Mumbletune.shutdown
	end

	Thread.stop # we're done here
end