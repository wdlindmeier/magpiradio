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

require 'serialport'
require File.join(File.dirname(__FILE__), 'radio_globals')

$semaphore = Mutex.new
$serial_port = nil
$baud_rate = 9600
$data_bits = 8
$stop_bits = 1
$parity = SerialPort::NONE

if $os_name == "linux"
	$port_str = "/dev/ttyS1" #"/dev/ttyACM0"
elsif $os_name == 'darwin'
	$port_str = "/dev/tty.usbmodemfa141"
end

at_exit { 
	
	Magpi_Serial::close_serial

}

module Magpi_Serial

	def self.open_serial(port_name)

		SerialPort::new(port_name, $baud_rate, $data_bits, $stop_bits, $parity)

	end

	def self.close_serial

		$serial_port.close if $serial_port
		$serial_port = nil

	end

	def self.send_initial_serial_packet

		buff = []
		
		loop do

			serial_read = $serial_port.getc #$serial_port.getc

			if serial_read

				char = serial_read.chr.to_s
				
				if char == "?"

					# We have a serial port. Send it the initial salvo.
					# Last channel value, number of channels.
					# For the time being, we'll just set the previous value to 0... not sure if it really matters

					# Just keep sending the data until we get a response
					$serial_port.write "0,#{Magpi_Content::num_channels},\n"

				elsif char != "\n"

					buff << char

				else
					
					line = buff.join.to_s
					buff = []
					if line.include?(',')
						break
					end

				end

			end
		end

	end

	def self.open_serial_connection_and_read_with_block(block)

		begin 

			$serial_port = open_serial($port_str)

		rescue Errno::EIO => e

			puts "Retrying serial port"

			retry

		end

		puts "Got a serial port: #{$serial_port}"

		$serial_port.flush

		send_initial_serial_packet

		read_serial_data(block)

	end

	def self.read_serial_data(block)

		begin		

			#just read forever
			buff = []

			while $serial_port && !$serial_port.closed? do 

				char = $serial_port.getc.to_s

				if char != "\n"
					buff << char
				else
					line = buff.join.to_s
					if !line.empty?

						vals = line.split(",").map(&:to_i)
						# puts vals.inspect
						if vals.count > 2

							serial_args = {
								:LKNOB => vals[0],
								:RKNOB => vals[1],
								:BUTTON => vals[2]
							}

							block.call(serial_args)

						end
					end
					buff = []
				end
			end	

		rescue Exception => e

			# NOTE: If the $serial_port was nilled out, lets assume it was intentional
			if !!$serial_port

				puts "WARNING: Caught exception: #{e}. Closing serial port."
				puts e.backtrace
				close_serial
				open_serial_connection_and_read_with_block(block)

			end

		end

	end

	def self.observe_serial_thread(&block)

		Thread.new {
			
			$semaphore.synchronize {

				begin 
					
					open_serial_connection_and_read_with_block(block)

				rescue Exception => e

					puts "EXCEPTION: #{e}"

					close_serial

				end
			
				close_serial

			}
		}

	end

end