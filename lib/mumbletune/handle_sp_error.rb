module Mumbletune

	# The Spotify Metadata API seems to throw 502 (Bad Gateway) errors *a lot*.
	# 	There's some complaint about this online, and I can reproduce it with
	# 	plenty of REST clients, so I am sure it's Spotify's problem. But they
	# 	don't seem too interested in fixing what appears to be a long-standing
	# 	issue. Ho hum.
	def self.handle_sp_error
		begin
			yield
		rescue MetaSpotify::ServerError => err
			puts "Caught ServerError: #{err}"
			failed ||= 0
			failed += 1
			if failed < 4
				sleep 1
				retry
			else
				raise
			end
		end
	end
end