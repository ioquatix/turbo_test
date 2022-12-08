# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2022, by Samuel Williams.

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
