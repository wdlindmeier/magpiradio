#!/usr/bin/ruby

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

require "cgi"
require "net/http"

cgi = CGI.new
query = cgi.params['q'][0] if cgi.params['q']
query ||= "Hello World"
voice = cgi.params['v'][0] if cgi.params['v']
voice ||= "Alex"
say_me = URI.decode(query)

# Some common replacements 
say_me.gsub!("\\!", '!')
say_me.gsub!(/\bim\b/i, "I'm")
say_me.gsub!(/\bid\b/i, "I'd")
say_me.gsub!(/\bive\b/i, "I've")
say_me.gsub!(/\bill\b/i, "I'll")

say_dir = '/Library/WebServer/Documents/say'

# NOTE: This may be insecure. Input params should be sanitized. 
# USE AT YOUR OWN RISK
`rm -f #{say_dir}/tmp.mp3 && /usr/bin/say -o #{say_dir}/tmp.m4a -v "#{voice}" "#{say_me}" && /Applications/ffmpegX.app/Contents/Resources/ffmpeg -i #{say_dir}/tmp.m4a #{say_dir}/tmp.mp3`
cgi.out("status" => "302", "Connection" => "close", "Content-Length" => 1, "Location" => '/say/tmp.mp3') {' '}
exit