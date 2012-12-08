require File.join(File.dirname(__FILE__), 'stream_channel')
require File.join(File.dirname(__FILE__), '../radio_audio_playback')

class DynamicStreamChannel < StreamChannel

	def initialize(stream_client, channel_name, audio_file_name, stream_method, *stream_args)
		super
		update_tracking_params(stream_args)		
	end

	def update_tracking_params(tracking_params)

		puts "update_tracking_params"

		# Speak the new stream
		@stream_args = [tracking_params, '@magpiradio'].flatten

		# Restart the broadcast if we're mid-stream
		if self.is_broadcasting
			
			# NOTE: I don't actually have to restart it. 
			# If this is the current channel and it's not broadcasting, Magpi_Content will automatically
			# start broadcasting
			self.is_broadcasting = false
			# self.begin_broadcast

		end
	end

	def _handle_command_tweet(tweet)

		txt = tweet.text.gsub(/^\@magpiradio/i, '')
		if txt.match(/^\s*\$/)
			# This is a command

			cmd = txt.sub(/^\s*\$\s*/, '')
			tokens = cmd.downcase.split(' ')

			puts "Received a command: #{cmd}"

			if tokens.count > 0
				case tokens[0]
				when 'request'
					# Update the tracking vars
					new_tracking_params = tokens[1..-1]
					new_tracking_params = new_tracking_params.join(' ').split(',').map{ |a| 
						# Not everything makes a good query, so we'll be restrictive about the filtering
						a.gsub!(/[^\w@_#\s]/, '')
						a.strip!
						a.empty? ? nil : a
					}.uniq.compact
					if new_tracking_params.count > 0
						puts "NOTE: tracking params has been updated: #{new_tracking_params.inspect}"
						self.update_tracking_params(new_tracking_params)
					else
						puts "WARNING: Ignored some tags #{tokens[1..-1].inspect}"
					end
				when 'voice'
					if voice_name = tokens[1..-1].join(' ')
						voice_name = voice_name.downcase
						$VOICES ||= ["agnes", "albert", "alex", "bad news", "bahh", "bells", "boing", "bruce", "bubbles", "cellos", "deranged", "fred", "good news", "hysterical", "junior", "kathy", "pipe organ", "princess", "ralph", "trinoids", "vicki", "victoria", "whisper", "zarvox"]
						if $VOICES.include?(voice_name)
							self.voice = voice_name
							Magpi_AudioPlayback::Say::set_voice(self.voice)
						else
							puts "ERROR: Couldn't find voice #{voice_name}"
						end
					end
				end									
			end

		else
			
			# Ignore everything else
			puts "Ignoring non-command @tweet: #{txt}"

		end

	end

	def queue_next_tweet(tweet)
		if tweet.in_reply_to_screen_name == "magpiradio"
			_handle_command_tweet(tweet)
		else
			super 
		end	
	end

	def begin_broadcast

		puts "Begin tracking #{@stream_args.inspect}"

		#Magpi_AudioPlayback::play_audio_file("audio/dialup_soft.wav", true, -1) # Loop the dialup sound 

		# Announce the tracking command, since these can change
		speakable_querries = @stream_args - ['@magpiradio']

		# Use the same voice as the channel names
		Magpi_AudioPlayback::Say::set_voice('vicki')

		playback_duration = Magpi_AudioPlayback::Say::say("Now playing: #{speakable_querries.join(" and ").gsub('#', 'hash tag ')}", true)
		
		Magpi_AudioPlayback::Say::set_voice(self.voice)

		sleep playback_duration+1

		super

	end

end