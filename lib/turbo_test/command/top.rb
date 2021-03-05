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

require_relative 'run'
require_relative 'list'
require_relative '../version'

require 'samovar'

module TurboTest
	module Command
		# The top level command for the `falcon` executable.
		class Top < Samovar::Command
			self.description = "A parallel test runner."
			
			# The command line options.
			# @attribute [Samovar::Options]
			options do
				option '-h/--help', "Print out help information."
				option '-v/--version', "Print out the application version."
			end
			
			# The nested command to execute.
			# @name nested
			# @attribute [Command]
			nested :command, {
				'run' => Run,
				'list' => List,
			}, default: 'run'
			
			# Prepare the environment and invoke the sub-command.
			def call
				if @options[:version]
					puts "#{self.name} v#{VERSION}"
				elsif @options[:help]
					self.print_usage
				else
					@command.call
				end
			end
		end
	end
end
