require 'mumbletune/mumble_client'
require 'mumbletune/mpd_client'
require 'mumbletune/messages'
require 'mumbletune/track'
require 'mumbletune/collection'
require 'mumbletune/sp_uri_server'
require 'mumbletune/spotify_track'
require 'mumbletune/resolver'
require 'mumbletune/handle_sp_error'

require 'optparse'
require 'yaml'
require 'eventmachine'
require 'rubypython'

module Mumbletune
	class << self
		attr_reader :player, :mumble, :uri_server, :config
	end

	# parse command line options
	config_file = nil
	OptionParser.new do |opts|
		opts.banner = "Usage: mumbletune.rb [options]"
		opts.on("-c", "--config FILE", "=MANDATORY", "Path to configuration file") do |file|
			config_file = file
		end
		opts.on("-h", "--help", "This help message") do
			puts opts.help()
			exit
		end
	end.parse!
	raise OptionParser::MissingArgument unless config_file

	# load configuration file
	@config = YAML.load_file(config_file)

	# load spotify-websocket-api
	puts ">> Loading Spotify APIs..."
	RubyPython.start(:python_exe => 'python2.7')
	Spotify = RubyPython.import('spotify_web.friendly').Spotify

	# open URI server
	uri_thread = Thread.new do
		SPURIServer::Server.run!
	end

	# initialize player
	play_thread = Thread.new do
		@player = Player.new
	end

	# connect to mumble & start streaming
	mumble_thread = Thread.new do
		@mumble = MumbleClient.new
		@mumble.connect
		@mumble.stream
	end

	# shutdown code
	def self.shutdown
		puts "\nGoodbye forever. Exiting..."
	 	exit
	end

	# exit when Ctrl-C pressed
	EventMachine.schedule do
		trap("INT") { Mumbletune.shutdown }
	end

	# testing
	# sleep 3
	# @player.command_test_load
	# @player.command_play

	Thread.stop # wake up to shut down
	self.shutdown

end