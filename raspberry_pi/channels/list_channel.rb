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