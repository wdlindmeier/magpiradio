Magpi Radio
===========

A Twitter Radio for Raspberry Pi and Arduino. Featured on Hack-a-day, Adafruit and Make!

A Brief Overview:
http://itp.nyu.edu/~wdl225/work/?p=275

Some Technical Details:
http://itp.nyu.edu/~wdl225/work/?p=286

The Twitter Stream:
http://twitter.com/magpiradio

Requirements
------------
Magpi Radio was designed to run on a Raspberry Pi running Debian Wheezy, but it may also work on OS X and other systems.

Software requirements:

- SDL library (SMPEG must be installed for mp3 playback): http://www.libsdl.org/ 
- SDL_mixer library. This is the SDL module that controls audio playback.
- ruby (tested using ruby 1.9.3)
- The ruby-sdl-ffi gem: http://github.com/jacius/ruby-sdl-ffi
- The twitter ruby gem: http://sferik.github.com/twitter/
- The tweetstream gem: http://github.com/intridea/tweetstream
- ffmpeg (optionally for the OS X say server): http://www.ffmpegx.com/

API requirements:

- A Google API Key. Enable Google Maps Geolocation API in your console. (https://code.google.com/apis/console)
- Twitter API OAuth Credentials. Read and write permissions should be enabled. 

Configure
---------
1. Once you clone the source, copy the file api_config_sample.rb to api_config.rb. Update the value of the global variables with your API credentials and Twitter account name.

2. Create a "tweets" folder within audio/. This is where the network audio files will be stored.
$ mkdir audio/tweets

3. Update Magpi_Content::configure to use your own list channels. This could also be handled in a config file, or a channel could be created from all of the account lists. Suggestions and pull-requests are welcome.

4. Upload the Arduino code to your Uno.

5. Connect your hardware components based on the system diagram found here: http://itp.nyu.edu/~wdl225/work/wp-content/uploads/2012/12/system_diagram.jpg

6. (Optional) Install the say.rb script on your web-server. I've dropped it into /Library/WebServer/CGI-Executables on my Mac with Apache running. This will allow you to use your own machine to generate the audio files. The tts will default to using tts-api.com if you don't specify one. If tts-api is unavailable, the script will try to use `espeak` on the Pi.

Running
-------
Without a custom text-to-speech server:

$ ./radio

With a custom text-to-speech server (e.g. using the say.rb script on 10.0.1.4):

$ ./radio.rb "http://10.0.1.4/cgi-bin/say.rb?q=__QUERY__&v=__VOICE__"

When you run the script, you may get these SDL warnings:

Warning: Could not load SDL_image.
Warning: Could not load SDL_ttf.
Warning: Could not load SDL_gfx.

These can be ignored, because Magpi Radio doesn't use the graphics and imaging components of SDL.

Twitter Interface
-----------------
If the radio is tuned to the "Any Requests?" channel, you can change the search query with the following tweet:

@magpiradio $ request #new_search

Replace @magpiradio with your own Twitter account and #new_search with whatever string you'd like to listen to.

If you're running the say.rb tts script, you can also change the voice of the Request channel with the following tweet:

@magpiradio $ voice zarvox

Again, replace @magpiradio with your account and "zarvox" can be any of the following voices:

agnes, albert, alex, bad news, bahh, bells, boing, bruce, bubbles, cellos, deranged, fred, good news, hysterical, junior, kathy, pipe organ, princess, ralph, trinoids, vicki, victoria, whisper, zarvox

Contact
-------
Magpi Radio was created as a student project by William Lindmeier at ITP/NYU. 
Email me at wdl225@nyu.edu