require 'bundler/setup'

require 'mumbletune/version'
require 'mumbletune/log'
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
		attr_reader :player, :mumble, :uri_server, :config, :verbose,
					:access_log, :error_log, :log_level
	end

	# defaults
	@verbose 		= false
	config_file 	= nil
	@log_level		= :INFO

	# parse command line options
	config_file = nil
	opts = OptionParser.new do |opts|
		opts.banner = "Usage: mumbletune.rb [options]"
		opts.on("-c", "--config FILE", "Path to configuration file") do |file|
			config_file = file
		end
		opts.on("-l", "--log-level LEVEL", "Set log level severity. Defaults to INFO") do |level|
			@log_level = level.upcase.to_sym
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
		puts "Error: Config file not provided"
		puts opts.help
		exit
	end

	# load configuration file
	@config = YAML.load_file(config_file)

	# initialize logs
	log = Mumbletune::Log.new
	@access_log = log.access
	@error_log  = log.error	

	@error_log.info "Hello. Starting up..."

	# initialize player
	play_thread = Thread.new do
		@player = HallonPlayer.new
		puts "survived init"
		@player.connect
		puts ">> Connected to Spotify."
		@error_log.info "startup: Connected to Spotify"
	end

	# connect to mumble & start streaming
	sleep 0.1 until @player && @player.ready
	mumble_thread = Thread.new do
		@mumble = MumbleClient.new
		@mumble.connect
		puts ">> Connected to Mumble server at #{self.config['mumble']['host']}."
		@error_log.info "startup: Connected to Mumble server at #{self.config['mumble']['host']}."
		@mumble.stream
	end

	# shutdown code
	def self.shutdown
		@error_log.info "Shutting down..."
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
		@error_log.info "Goodbye."
	 	exit
	end

	# exit when Ctrl-C pressed
	Signal.trap("INT") do
		Mumbletune.shutdown
	end

	# log unhandeled exceptions
	at_exit do
		unless $!.nil? || $!.is_a?(SystemExit)
			@error_log.fatal <<-END
#{$!.class}: #{$!.message}
Backtrace:
#{$@.join "\n"}
END
		end
	end

	Thread.stop # we're done here
end