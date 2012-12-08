#--
#
# This file is one part of:
#
# Magpi Radio - A Twitter Radio for Raspberry Pi
#
# Copyright (c) 2012  William Lindmeier
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
#++

require 'ruby-sdl-ffi'
require 'net/http'
require File.join(File.dirname(__FILE__), 'radio_globals')

$cached_audio = {}
$audio_is_configured = false
$audio_frame = 0
$voice_name = 'alex'

module Magpi_AudioPlayback

	MAX_AUDIO_VOLUME = 128
	MIN_AUDIO_VOLUME = 1

	def self.open_audio

		if !$audio_is_configured
			# Set it to mute until we have a channel
			SDL::Mixer::OpenAudio( 22050, SDL::AUDIO_S16SYS, 2, 1024 )
			$audio_is_configured = true
		end

	end

	def self.set_volume(vol)

		if vol.to_i < MIN_AUDIO_VOLUME

			Magpi_AudioPlayback::close_audio()

		else

			Magpi_AudioPlayback::open_audio() # Only opens if it's not already
			SDL::Mixer::VolumeMusic(vol.to_i)

		end

	end

	def self.speak_tweet(tweet_string)

		Say::say(tweet_string, true)

	end

	def self.play_audio_file_with_media_player(audio_file, player_path)
		t = Thread.new {
			`#{player_path} #{audio_file} > /dev/null 2>&1`
		}
		t.run
	end

	def self.fade_out_music(duration)
		
		SDL::Mixer::FadeOutMusic(duration)

	end

	def self.play_audio_file(filename, should_cache=false, loop_count=1)

		if $audio_is_configured

			aud = nil;
			path = File.expand_path(filename)

			if !File.exists?(path)
				puts "ERROR: Audio file doesn't exist. #{path}"
				return 0
			end

			if should_cache
				
				aud = $cached_audio[path]

			end

			if !aud
				
				aud = SDL::Mixer::LoadMUS( path )

				if aud.to_ptr.null?
					
					puts "ERROR: Could not load audio. #{SDL::GetError()}"
					return 0

				elsif should_cache

					$cached_audio[path] = aud

				end

			end

			$current_audio = aud

			duration = 0
			if path.match(/\.mp3$/)
				duration = `mp3info -p "%S" #{path}`
			end

			SDL::Mixer::PlayMusic( aud.to_ptr, loop_count ) # 2nd arg is the loop count. -1 is repeat

			return duration.to_i + 1

		end

		return 0

	end

	def self.close_audio
		
		if $audio_is_configured
			SDL::Mixer::CloseAudio()
			$audio_is_configured = false
		end
		
	end

	module Say

		def self.say(msg, should_use_network=true)
			escaped_msg = msg.gsub('"','\\"')
			send "say_#{$os_name}", escaped_msg, should_use_network
		end

		def self.set_voice(voice_name)
			$voice_name = voice_name
		end

		def self.say_network(msg)
			# Render and download as an mp3
			query = URI.escape(msg).gsub('"','\"').gsub('!', '\!')

			# Whitelist the characters allowed in the URL
			# query = URI.escape(msg.gsub(/[^\w\.\!\?\@\s]/, '').gsub(/!/, '\!').gsub(/\s+/, ' '))

			# Keep the 100 most recent
			$audio_frame = ($audio_frame + 1) % 100;
			tmp_filename = File.expand_path(File.join(File.dirname(__FILE__), "audio/tweets/#{$audio_frame}.mp3"))

			`rm -f #{tmp_filename} && wget -O #{tmp_filename} "#{$say_url.sub('__QUERY__', query).sub('__VOICE__', $voice_name)}" > /dev/null 2>&1`
			if !File.exists?(tmp_filename)
				puts "WARNING: Could not find audiofile #{tmp_filename}"
				# If for whatever reason we didn't get the file, just say it locally
				say(msg, false)
				return 0
			else
				Magpi_AudioPlayback::play_audio_file(tmp_filename)
			end
		end

		def self.say_darwin(msg, should_use_network)
			if should_use_network
				say_network(msg)
			else
				`say "#{msg}"`
				return 0
			end
		end

		def self.say_linux(msg, should_use_network)
			if should_use_network
				say_network(msg)
			else
				#`echo "#{msg}" | festival --tts > /dev/null 2>&1`
				`espeak "#{msg}" > /dev/null 2>&1`
				return 0
			end
		end

	end

end

at_exit { 
	
	Magpi_AudioPlayback::close_audio

}