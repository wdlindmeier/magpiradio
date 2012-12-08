#! /usr/bin/ruby

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

require 'rubygems'
require 'thread'

require File.join(File.dirname(__FILE__), 'radio_globals')
require File.join(File.dirname(__FILE__), 'radio_serial')
require File.join(File.dirname(__FILE__), 'radio_interface')
require File.join(File.dirname(__FILE__), 'radio_location')
require File.join(File.dirname(__FILE__), 'radio_twitter')

if custom_say_url = ARGV[0]
	$say_url = custom_say_url
end

puts "Fetching audio from #{$say_url}"

Signal.trap("SIGINT") do
	
	puts "Quitting MagPi Radio. One moment...\n"

	begin 

		Magpi_Serial::close_serial
		Magpi_AudioPlayback::close_audio
		if $SHOULD_TWEET_STATUS
			Magpi_Twitter::tweet_shutting_down
		end

	rescue Exception => e

		puts "Caught Exception: #{e}"
		puts e.backtrace

	end

	exit

end

$SHOULD_TWEET_STATUS = true

Magpi_Twitter::configure
# NOTE: Location should be retrieved before content is because the location channel is 
my_loc_info = Magpi_Location::get_location_info
Magpi_Twitter::tweet_location(my_loc_info)
Magpi_Content::configure

# Don't open audio initially. Wait until we get volume readings
#Magpi_AudioPlayback::open_audio

$threads = []

# Serial Thread
$threads << Magpi_Serial::observe_serial_thread do |serial_args|

	#puts serial_args.inspect

	begin
		
		volume_knob_val = serial_args[:LKNOB]
		channel_knob_val = serial_args[:RKNOB]
		button_val = serial_args[:BUTTON]

		Magpi_Interface::set_channel_knob_value(channel_knob_val)
		Magpi_Interface::set_volume_knob_value(volume_knob_val)
		Magpi_Interface::set_favorite_button_value(button_val)

	rescue Exception => e

		puts "WARNING: Caught serial exception: #{e}"
		puts e.backtrace

	end

end

# Twitter Thread
if $SHOULD_TWEET_STATUS
	$threads << Thread.new {

		loop do
			begin 

				Magpi_Twitter.tweet_messages_in_queue

			rescue Exception => e

				puts "WARNING: Twitter Exception: #{e}"
				puts e.backtrace
				
			end
			sleep 3
		end
	}
end

# Run the app
$threads.each do |t|
	t.run
end

loop do
	sleep 10
end