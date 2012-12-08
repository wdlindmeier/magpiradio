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
require 'tweetstream'
require 'twitter'
require 'net/http'
require File.join(File.dirname(__FILE__), 'radio_content')

# IMPORTANT:
# Create a file called api_config.rb based on api_config_sample.rb that contains your
# Twitter API credentials
require File.join(File.dirname(__FILE__), 'api_config')

$twitter_client = nil;
$stream_client = nil;
$twitter_is_configured = false;
$last_tweet = nil;


module Magpi_Twitter

	@@tweet_queue = []

	def self.configure

		TweetStream.configure do |config|
		  config.consumer_key       = $TW_CONSUMER_KEY
		  config.consumer_secret    = $TW_CONSUMER_SECRET
		  config.oauth_token        = $TW_OAUTH_TOKEN
		  config.oauth_token_secret = $TW_OAUTH_TOKEN_SECRET
		  config.auth_method        = :oauth
		end
		$stream_client = TweetStream::Client.new

		$twitter_client = Twitter::Client.new( 	:consumer_key => $TW_CONSUMER_KEY,
		  										:consumer_secret => $TW_CONSUMER_SECRET,
		  										:oauth_token => $TW_OAUTH_TOKEN,
		  										:oauth_token_secret => $TW_OAUTH_TOKEN_SECRET );

		$twitter_is_configured = true;

	end

	def self.rest_client
		if $twitter_is_configured
			return $twitter_client
		end
		puts "WARNING: Twitter client has not been initialized"
	end

	def self.stream_client
		if $twitter_is_configured
			return $stream_client
		end
		puts "WARNING: Twitter client has not been initialized"
	end


	def self.tweet_messages_in_queue
		
		queue = @@tweet_queue
		@@tweet_queue = []

		queue.each do |tweet|

			puts "Sending tweet: #{tweet}"

			$twitter_client.update(tweet, {
					# Do we want to broadcast the exact location?
					# :lat => loc_info['lat'],
					# :lng => loc_info['lng']
				});

		end

	end

	def self.set_last_spoken_tweet(tweet)
		
		$last_tweet = tweet
		
	end

	def self.favorite_last_spoken_tweet

		if $twitter_is_configured && $last_tweet
			$twitter_client.favorite($last_tweet.id)
		end

	end

	def self.tweet_location(loc_info)

		if $twitter_is_configured

			@@tweet_queue << "Now broadcasting on #{loc_info['ip']} from #{loc_info['name']} at #{Time.now.strftime("%I:%M%p")} \#hello"

		end

	end

	def self.tweet_current_channel(channel, time_changed)

		if $twitter_is_configured

			if channel.is_a? OffChannel

				@@tweet_queue << "Turned radio off at #{time_changed.strftime("%I:%M%p")} \#channel"

			else

				@@tweet_queue << "Tuned into \"#{channel.name}\" at #{time_changed.strftime("%I:%M%p")} \#channel"

			end

		end

	end

	def self.tweet_shutting_down
		
		if $twitter_is_configured
			# Call this directly, not from the queue, so it's immediate
			$twitter_client.update("Signing off at #{Time.now.strftime("%I:%M%p")}. \#goodbye")

		end

	end

end