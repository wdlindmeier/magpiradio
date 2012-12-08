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

require File.join(File.dirname(__FILE__), 'channel')

class ListChannel < TwitterRadioChannel

	def get_next_tweets

		if @rest_client

			# NOTE: Getting an "invalid" since_id error
			self.last_tweet_id = 12345 if !self.last_tweet_id  # TEST
			puts "Channel self.last_tweet_id: #{self.last_tweet_id}"
			
			tweets = @rest_client.list_timeline(@rest_client.current_user.screen_name, 
															self.name, 
															:include_rts => false, # Does this work?
															:count => 100, # Not sure what the max is
															:since_id => self.last_tweet_id)
			# NOTE: Speaking older tweets first
			return tweets.sort{ |a,b| a.id <=> b.id }
		else
			puts "WARNING: Twitter REST client doesn't exist"
		end
		
	end

end