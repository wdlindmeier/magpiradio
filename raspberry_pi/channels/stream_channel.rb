require File.join(File.dirname(__FILE__), 'channel')

class StreamChannel < TwitterRadioChannel

	def initialize(stream_client, channel_name, audio_file_name, stream_method, *stream_args)

		super(nil, channel_name, audio_file_name)
		@stream_client = stream_client
		@stream_method = stream_method
		@stream_args = stream_args
		@last_tweet = nil
				
	end

	def queue_next_tweet(tweet)
		@last_tweet = tweet
	end

	def begin_broadcast

		if !self.is_broadcasting

			Magpi_AudioPlayback::play_audio_file("audio/dialup_soft.wav", true, -1) # Loop the dialup sound 

			self.is_broadcasting = true

			Thread.kill(@thread) if @thread
			Thread.kill(@playback_thread) if @playback_thread

			@last_tweet = nil

			@playback_thread = Thread.new {

				begin

					my_last_tweet = nil

					loop do 
						if @last_tweet && my_last_tweet != @last_tweet
							# Play it
							my_last_tweet = @last_tweet
							# puts "Playing tweet id: #{my_last_tweet.id}"
							_broadcast_tweet_with_delay(my_last_tweet, 0)
						end
						sleep 0.25
					end

				rescue Exception => e

					puts "WARNING: Caught channel exception: #{e}"
					puts e.backtrace

				end

			}

			@thread = Thread.new {

				sleep 2

				Magpi_AudioPlayback::play_audio_file("audio/meanwhile.wav", true, -1) 

				begin
					
					@stream_client.send(@stream_method, *@stream_args) do |tweet|
					
						if self.is_broadcasting

							begin 

								# Make sure it's not from me (e.g. a status tweet)
								# Also only speak English tweets
								if  tweet.user.screen_name.downcase != 'magpiradio' &&
									tweet.user.lang.downcase == 'en'

									#puts "Queueing Tweet"

									# NOTE:
									# We're doing playback it a different thread so the loop doesn't get behind the stream
									# Newer tweets will always overwrite any tweets waiting to be played.
									# This can happen if there's a high-volume of tweets
									self.queue_next_tweet(tweet)

								else 

									puts "Ignoring tweet. tweet.user.screen_name: #{tweet.user.screen_name}"

								end

							rescue Exception => e

								puts "WARNING: Caught an exception in the stream: #{e}"
								puts e.backtrace

							end

						else

							@stream_client.stop							
							return

						end

					end

				rescue Exception => e

					puts "WARNING: Caught channel exception: #{e}"
					puts e.backtrace

				end

			}

			@playback_thread.run 
			@thread.run

		end

	end

	def end_broadcast
		
		#@stream_client.stop		
		Thread.kill(@playback_thread) if @playback_thread
		@playback_thread = nil
		super 

	end

end