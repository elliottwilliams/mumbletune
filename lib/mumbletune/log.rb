require "logger"
require "fileutils"

module Mumbletune
	class Log
		attr_reader :access, :error
		def initialize(log_level = :INFO)
			log_dir = Mumbletune.config["log_dir"]
			access  = File.join(log_dir, "mumbletune.access.log")
			error   = File.join(log_dir, "mumbletune.error.log")

			# Create directories and logfiles if necessary
			FileUtils.mkdir_p log_dir
			FileUtils.touch access
			FileUtils.touch error

			# Start the loggers!
			@access = Logger.new(access, "weekly")
			@error  = Logger.new(error, "weekly")

			# Set error level
			@error.level = Logger.const_get log_level
		end

	end
end