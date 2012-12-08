require File.join(File.dirname(__FILE__), 'radio_globals')
require File.join(File.dirname(__FILE__), 'radio_twitter')
require File.join(File.dirname(__FILE__), 'channels/channel')
require File.join(File.dirname(__FILE__), 'channels/list_channel')
require File.join(File.dirname(__FILE__), 'channels/stream_channel')
require File.join(File.dirname(__FILE__), 'channels/dynamic_stream_channel')
require File.join(File.dirname(__FILE__), 'channels/off_channel')

$channels = [];
$current_channel = nil;
$time_last_channel_changed = Time.new(0)
$has_tweeted_channel = false
$last_tweeted_channel = nil
$request_channel = nil

module Magpi_Content

	def self.configure

		# "Off" channel
		$channels << OffChannel.new

		# List channels
		$channels << ListChannel.new(Magpi_Twitter::rest_client, "All", "audio/ch_all.wav")
		$channels << ListChannel.new(Magpi_Twitter::rest_client, "News", "audio/ch_news.wav")
		$channels << ListChannel.new(Magpi_Twitter::rest_client, "Weird", "audio/ch_weird.wav")
		$channels << ListChannel.new(Magpi_Twitter::rest_client, "Humor", "audio/ch_humor.wav")
		
		# Streaming channels
		coords = Magpi_Location::current_coords
		# THis is NYC: '-74,40,-73,41'
		# NOTE: Making the lng range slightly smaller because the world is shaped funny
		# This should really be handled "correctly", but for the moment it just works well in NYC
		lat_delta = 0.025 #0.1
		lng_delta = 0.025# 0.075
		coord_range = "#{coords['lng'].to_f-lat_delta},#{coords['lat'].to_f-lng_delta},#{coords['lng'].to_f+lat_delta},#{coords['lat'].to_f+lng_delta}"
		$channels << StreamChannel.new(Magpi_Twitter::stream_client, "Nearby", "audio/ch_nearby.wav", :locations, coord_range)

		
		at_channel = StreamChannel.new(Magpi_Twitter::stream_client, "@magpiradio", "audio/ch_at.wav", :track, '@magpiradio')
		# If this is a command, ignore it
		# NOTE: These are executed in the order we add them, so this has to be first
		at_channel.tweet_filters << lambda{ |tweet_txt| 
			if tweet_txt.match(/^\s*\@magpiradio\s*\$/i)
				return nil
			end
			tweet_txt
		}
		at_channel.tweet_filters << lambda{ |tweet_txt| 
											if tweet_txt.match(/^\@magpi/i)
												# If the tweet starts w/ the handle, just remove it
												tweet_txt.gsub('@magpiradio', '')
											else
												# Otherwise, spell it out
												tweet_txt.gsub('@magpiradio', "magpie radio") 
											end
										  }
		
		$channels << at_channel

		$request_channel = DynamicStreamChannel.new(Magpi_Twitter::stream_client, "Any Requests?", "audio/ch_any_requests.wav", :track, "dreaming")
		$channels << $request_channel

	end	

	def self.is_radio_off
		return $current_channel.is_a?(OffChannel)
	end

	def self.request_channel
		return $request_channel
	end

	def self.num_channels
		return $channels.length
	end

	def self.set_current_channel_index(channel_index)

		select_channel = $channels[channel_index]

		if select_channel && $current_channel != select_channel

			$current_channel.end_broadcast if $current_channel

			$has_tweeted_channel = false

			$time_last_channel_changed = Time.now

			$current_channel = select_channel

			puts "Changed Channel to \"#{$current_channel.name}\""

			if self.is_radio_off
				# Make it silent
				puts "Turning audio off"
				Magpi_AudioPlayback::close_audio()
			else
				# Crank it up
				puts "Turning audio on"
				Magpi_AudioPlayback::open_audio()
				Magpi_AudioPlayback::play_audio_file($current_channel.audio_file_name, true) if $current_channel.audio_file_name
			end

		end

		if $current_channel && !$current_channel.is_broadcasting

			if Time.now - $time_last_channel_changed > 2

				$current_channel.begin_broadcast

			end

		end

		if !$has_tweeted_channel
			
			# Tweet the current channel if it's been listened to for more than 10 seconds.
			# NOTE: This might cause some rate limit issues if the channel is changed too much

			if Time.now - $time_last_channel_changed > 10
				
				$has_tweeted_channel = true

				# Only tweet if the channel has changed
				if $last_tweeted_channel != $current_channel.name

					# Don't tweet "off" when we first boot up
					unless self.is_radio_off && !$last_tweeted_channel

						Magpi_Twitter::tweet_current_channel($current_channel, $time_last_channel_changed)
						$last_tweeted_channel = $current_channel.name

					end

				end

			end

		end

	end

	# Filter any hash tags to URLs
	def self.spoken_tweet(tweet,sender)

		if !tweet or tweet.strip.empty?
			return nil
		end
		
		if tweet[0..1] == 'RT' || tweet[0] == '@'
			return nil
		end

		# downcase so acronyms are read like words
		# tweet.downcase!
		# nah

		# Remove visibility . 
		tweet.sub!(/^\./, '')

		# Remove HTML encoded chars
		tweet.gsub!(/\&\w+\;/, '')

		# Remove any URLs
		tweet.gsub!(/http\S+/, '')

		tweet.gsub!('&amp;', '&')

		# Lots of people write 'im' rather than "I'm"
		tweet.gsub!(/\bim\b/i, "I'm")

		# Remove any hash tags ONLY at the end
		while match = tweet.match(/\#[\w_-]+\s*$/)
			tweet.sub!(match[0], '')
		end

		# Treat hashtags in the middle like normal words
		tweet.gsub!('#', '')

		# Remove via @...
		tweet.gsub!(/\s*(\()?via \@\S+(\))?/, '')

		# User specific-stuff
		case sender
		when 'TFLN'
			tweet.gsub!(/\(\d+\)\:/, '')
		end
		
		return tweet.strip
	end

end