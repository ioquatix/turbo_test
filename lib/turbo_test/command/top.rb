# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2022, by Samuel Williams.

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
