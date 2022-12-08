# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2022, by Samuel Williams.

require_relative 'command/top'

module TurboTest
	module Command
		# The main entry point for the `falcon` executable.
		# @parameter arguments [Array(String)] The command line arguments.
		def self.call(*arguments)
			Top.call(*arguments)
		end
	end
end
