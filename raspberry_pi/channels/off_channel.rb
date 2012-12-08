require File.join(File.dirname(__FILE__), 'channel')
require File.join(File.dirname(__FILE__), '../radio_audio_playback')

class OffChannel < TwitterRadioChannel

	def initialize
		super(nil,"off",nil)
	end


	def begin_broadcast

		self.is_broadcasting = true
		Magpi_AudioPlayback::fade_out_music(0)

	end

end
