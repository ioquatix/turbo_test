# frozen_string_literal: true

# Copyright, 2020, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'samovar'

require_relative '../server'
require_relative '../configuration'
require_relative '../rspec/job'

require 'bundler'

module TurboTest
	module Command
		class Run < Samovar::Command
			self.description = "Runs tests using a distributed fan-out queue."
			
			# The command line options.
			# @attribute [Samovar::Options]
			options do
				option '-n/--count <count>', "Number of instances to start.", default: Async::Container.processor_count, type: Integer
				
				option '-c/--configuration', "The configuration path to use.", default: "turbo_test.rb"
			end
			
			many :paths, "The test paths to execute."
			
			split :child_options, "Extra options to pass to the child process."
			
			# Prepare the environment and run the controller.
			def call
				Async.logger.info(self) do |buffer|
					buffer.puts "TurboTest v#{VERSION} preparing for maximum thrust!"
				end
				
				path = @options[:configuration]
				full_path = File.expand_path(path)
				configuration = Configuration.load(full_path)
				
				Bundler.require(:preload)
				
				if GC.respond_to?(:compact)
					GC.compact
				end
				
				server = Server.new(configuration)
				
				queue = paths.map do |path|
					[RSpec::Job, path]
				end
				
				server.host(queue)
				server.workers
				server.wait
			end
		end
	end
end
