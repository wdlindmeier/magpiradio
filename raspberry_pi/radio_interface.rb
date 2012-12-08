require 'ruby-sdl-ffi'
require File.join(File.dirname(__FILE__), 'radio_globals')
require File.join(File.dirname(__FILE__), 'radio_content')
require File.join(File.dirname(__FILE__), 'radio_audio_playback')
require File.join(File.dirname(__FILE__), 'radio_twitter')

$MAX_KNOB_VALUE = 1023
$prev_channel_value = -1
$prev_volume_value = -1
$prev_favorite_button_val = 0;

module Magpi_Interface

	def self.set_channel_knob_value(val)

		num_channels = Magpi_Content::num_channels

		if num_channels > 0
			Magpi_Content::set_current_channel_index(val)
		end

	end

	def self.set_volume_knob_value(val)

		vol = (Magpi_AudioPlayback::MAX_AUDIO_VOLUME * (val.to_f / $MAX_KNOB_VALUE.to_f)).to_i

		if vol != $prev_volume_value

			unless Magpi_Content::is_radio_off
				Magpi_AudioPlayback::set_volume(vol)
			end
			$prev_volume_value = vol

		end

	end

	def self.set_favorite_button_value(button_val)

		if button_val == 1 && $prev_favorite_button_val != 1
			
			# puts "Button Favorite Pressed"
			Magpi_Twitter::favorite_last_spoken_tweet

			# Plays a wolf whistle 
			# Not so awesome because it cuts off the current audio
			# Magpi_AudioPlayback::play_audio_file('audio/whistle.wav', true)

		end

		$prev_favorite_button_val = button_val

	end

end