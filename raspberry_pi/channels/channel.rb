require File.join(File.dirname(__FILE__), '../radio_content')
require File.join(File.dirname(__FILE__), '../radio_audio_playback')
require File.join(File.dirname(__FILE__), '../radio_twitter')

$MIN_SEC_BETWEEN_CALLS = (60*60)/15

$MIN_DELAY_BETWEEN_TWEETS = 1 # min seconds between tweets
# Maybe we can just let the download time be the buffer

class TwitterRadioChannel

	attr_accessor :last_tweet_id, :name, :audio_file_name, :is_broadcasting, :tweet_filters, :voice

	def initialize(rest_client, channel_name, audio_file_name=nil)

		self.name = channel_name
		self.audio_file_name = audio_file_name
		self.last_tweet_id = nil; # NOTE: This must start as nil
		self.voice = 'alex'
		@rest_client = rest_client

		# Tweet filters are additional blocks that are performed on the tweets before they are broadcast
		self.tweet_filters = []

	end

	def get_next_tweets

		return []

	end
	
	def _broadcast_tweet_with_delay(tweet, min_time_per_tweet)

		filtered_text = tweet.text

		self.tweet_filters.each do |filter_block|
			filtered_text = filter_block.call(filtered_text)
			break unless filtered_text
		end

		self.last_tweet_id = tweet.id if tweet.id > self.last_tweet_id.to_i

		puts ["@#{tweet.user.screen_name}:", tweet.text]

		# Filter the tweet
		speakable_tweet = Magpi_Content::spoken_tweet(filtered_text, tweet.user.screen_name)

		if speakable_tweet && !speakable_tweet.empty?

			# NOTE: This is no longer valid
			t = Time.now

			playback_duration = Magpi_AudioPlayback::speak_tweet(speakable_tweet)
			playback_duration = playback_duration.to_i
			
			tdelta = Time.now - t
			delay_for = min_time_per_tweet - tdelta - playback_duration
			delay_for = $MIN_DELAY_BETWEEN_TWEETS if delay_for < $MIN_DELAY_BETWEEN_TWEETS

			sleep playback_duration

			Magpi_Twitter::set_last_spoken_tweet(tweet)
			
			Magpi_AudioPlayback::play_audio_file("audio/meanwhile.wav", true, -1) 
			
			sleep delay_for

		else

			puts "Skipping. Tweet was filtered."

		end

	end

	def begin_broadcast

		if !self.is_broadcasting

			Magpi_AudioPlayback::Say::set_voice(self.voice)

			Magpi_AudioPlayback::play_audio_file("audio/dialup_soft.wav", true, -1) # Loop the dialup sound 

			self.is_broadcasting = true

			Thread.kill(@thread) if @thread

			@thread = Thread.new {

				begin

					puts "Beginning channel broadcast"
				
					last_call = Time.now - $MIN_SEC_BETWEEN_CALLS

					loop do

						break if !self.is_broadcasting

						time_since_last_call = Time.now - last_call

						if time_since_last_call >= $MIN_SEC_BETWEEN_CALLS

							puts "Getting new tweets for \"#{self.name}\""
						
							last_call = Time.now

							# NOTE: We can only call this 15 times an hour, so make sure it's 
							# at least 5 min between calls

							tweets = self.get_next_tweets

							puts "Got #{tweets.count} tweets"

							Magpi_AudioPlayback::play_audio_file("audio/meanwhile.wav", true, -1) 

							if tweets.count > 0

								#avg_tweet_secs = 3 # this is just a guess
								#spoken_duration = tweets.count * avg_tweet_secs				
								secs_per_tweet = $MIN_SEC_BETWEEN_CALLS / tweets.count
								secs_per_tweet = $MIN_DELAY_BETWEEN_TWEETS if secs_per_tweet < $MIN_DELAY_BETWEEN_TWEETS

								tweets.each do |tweet|

									if self.is_broadcasting

										_broadcast_tweet_with_delay(tweet, secs_per_tweet)

									else

										break

									end

								end
							
							end

						else

							secs_to_sleep = $MIN_SEC_BETWEEN_CALLS - time_since_last_call

							puts "Sleeping for #{secs_to_sleep} seconds for API Rate limiting"
							# Sleep until we can call again
							sleep secs_to_sleep

						end

					end

				rescue Exception => e

					puts "WARNING: Caught channel exception: #{e}"
					puts e.backtrace

				end

			}

			@thread.run

		end

	end

	def end_broadcast
		
		Thread.kill(@thread) if @thread
		@thread = nil
		self.is_broadcasting = false

	end

end