require 'forwardable'

module Mumbletune
	class Collection
		include Enumerable
		extend Forwardable

		attr_accessor :type,  :description, :user, :tracks, :history, :current_track

		def_delegators :@tracks, :length, :first, :last, :each, :any?, :empty?

		def initialize(type, tracks, description)
			@type = type
			@description = description
			@tracks = [tracks].flatten
			@history = Array.new
		end

		def next
			if @current_track
				@history << @current_track
				@tracks.delete @current_track
			end
			@current_track = @tracks.first
		end

		def empty?
			without_current = @tracks.dup
			without_current.delete_if { |t| t == @current_track }
			without_current.empty?
		end

		def any?
			!empty?
		end
	end
end