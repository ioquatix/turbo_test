# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2022, by Samuel Williams.

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
				
				option '-c/--configuration <path>', "The configuration path to use.", default: "turbo_test.rb"
			end
			
			many :paths, "The test paths to execute."
			
			# Prepare the environment and run the controller.
			def call
				Console.logger.info(self) do |buffer|
					buffer.puts "TurboTest v#{VERSION} preparing for maximum thrust!"
				end
				
				path = @options[:configuration]
				full_path = File.expand_path(path)
				
				configuration = Configuration.new
				
				if File.exist?(full_path)
					configuration.load(full_path)
				end
				
				configuration.finalize!
				
				Bundler.require(:preload)
				
				if GC.respond_to?(:compact)
					GC.compact
				end
				
				server = Server.new(configuration)
				
				queue = configuration.queue(
					paths&.map{|path| File.expand_path(path)}
				)
				
				results = server.run(queue)
				
				if results[:failed].zero?
					puts "All tests passed!"
				end
				
				return results
			end
		end
	end
end
