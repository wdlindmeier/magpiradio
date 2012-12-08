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

require 'net/http'
require 'openssl'
require 'rubygems'
require 'json'
require 'pp'

# IMPORTANT:
# Create a file called api_config.rb based on api_config_sample.rb that contains your
# Google API Key
require File.join(File.dirname(__FILE__), 'api_config')

$current_coords = {}

module Magpi_Location

	def self.current_coords
		return $current_coords
	end

	def self.get_location_info

		# Get IP Address
		
		loc_info = { 'ip' => "an undisclosed bunker", 'name' => "Cyberspace" }

		ip_info_str = Net::HTTP.get(URI.parse('http://freegeoip.net/json/'));

		if ip_info_str
			
			ip_info = JSON.parse(ip_info_str)
			ip_addr = ip_info['ip']

			if !ip_addr.empty?

				loc_info['ip'] = ip_addr

				geo_loc_info = get_geolocation_for_ip(ip_addr)				

				if geo_loc_info

					results = geo_loc_info['results']

					begin 

						$current_coords = results[0]['geometry']['location']

					rescue TypeError => e
						
						$current_coords = {}

					end

					loc_info['lat'] = $current_coords['lat']
					loc_info['lng'] = $current_coords['lng']

					begin

						hood = results.map{ |a| 
											a['address_components']
										  }.flatten.map{ |a| 
										  	a['types'].include?('political') ? a['long_name'] : nil 
										  }.compact[0..1].join(", ")
					
						loc_info['name'] = hood;

					rescue TypeError => e

					end

				end

			end

		else
			
			puts "No IP Address found"

		end

		return loc_info

	end

	def self.get_geolocation_for_ip(ip_addr)	
		# https://developers.google.com/maps/documentation/business/geolocation/

		uri = URI.parse("https://www.googleapis.com")
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE

		request = Net::HTTP::Post.new("/geolocation/v1/geolocate?key=#{$GOOGLE_API_KEY}")
		request.content_type = 'application/json'	
		json_body = {
			  "wifiAccessPoints" => surrounding_wifi_data
		}.to_json

		request.body = json_body
		response = http.request(request)

		if response.code.to_i < 300
			
			geoloc = JSON.parse(response.body)

			return get_location_name_for_geolocation(geoloc)

		else
			
			puts ["Error getting response. Status #{response.code}", response.message]

		end

		return nil

	end

	def self.get_location_name_for_geolocation(geoloc)

		latlng = geoloc['location']
		url = "http://maps.google.com/maps/api/geocode/json?latlng=#{latlng['lat']},#{latlng['lng']}&sensor=false"
		response = Net::HTTP.get_response(URI.parse(url));

		if response.code.to_i < 300		
			
			return JSON.parse(response.body)

		else

			puts ["Error getting response. Status #{response.code}", response.message] 

		end

		return nil

	end

	def self.scan_wifi

		return `iwlist scan 2>&1`

	end

	def self.surrounding_wifi_data

		if wifi_scan = scan_wifi
			cells = wifi_scan.split(/Cell \d+/)
			
			wifi_data = []
			cells.each do |cell|
				cell_info = {}
				if addr_line = cell.match(/Address\: (.+)\n/)
					cell_info['macAddress'] = addr_line[1].strip
				end
				if freq_line = cell.match(/Frequency\:.+\(Channel (\d+)\)/)
					cell_info['channel'] = freq_line[1].strip
				end	
				if signal_line = cell.match(/Signal level\=(\d+)\/100/)
					cell_info['signalToNoiseRatio'] = signal_line[1].strip
				end
				unless cell_info.empty?
					wifi_data.push(cell_info)
				end
			end
			return wifi_data
		end
		[] # return blank

	end

end
