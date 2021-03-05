# frozen_string_literal: true

# Copyright, 2021, by Samuel G. D. Williams. <http://www.codeotaku.com>
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
		class List < Samovar::Command
			self.description = "List tests available to be run."
			
			# The command line options.
			# @attribute [Samovar::Options]
			options do
				option '-c/--configuration <path>', "The configuration path to use.", default: "turbo_test.rb"
			end
			
			# Prepare the environment and run the controller.
			def call
				path = @options[:configuration]
				full_path = File.expand_path(path)
				
				configuration = Configuration.new
				
				if File.exist?(full_path)
					configuration.load(full_path)
				end
				
				configuration.finalize!
				
				configuration.jobs.each do |klass, path, **options|
					if options&.any?
						puts "#{klass}: #{path} #{options.inspect}"
					else
						puts "#{klass}: #{path}"
					end
				end
			end
		end
	end
end
