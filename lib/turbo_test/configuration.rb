# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2022, by Samuel Williams.

require_relative 'rspec/job'

module TurboTest
	class Configuration
		def initialize
			@loaded = false
			@worker = nil
			@jobs = []
		end
		
		attr_accessor :loaded
		attr_accessor :worker
		attr_accessor :jobs
		
		def load(path)
			loader = Loader.new(self, File.dirname(path))
			
			loader.instance_eval(File.read(path), path.to_s)
			
			return loader
		end
		
		def finalize!
			unless @loaded
				self.defaults!
			end
		end
		
		def queue(matching)
			if matching.nil? or matching.empty?
				# No filtering required, return all jobs:
				return @jobs.dup
			else
				return @jobs.select{|klass, path| matching.include?(path)}
			end
		end
		
		DEFAULT_JOB_CLASSES = [RSpec::Job]
		
		def defaults!(pwd = Dir.pwd)
			loader = Loader.new(self, pwd)
			
			loader.defaults!
			
			return loader
		end
		
		class Loader
			def initialize(configuration, base)
				@configuration = configuration
				@base = base
			end
			
			attr :path
			
			def worker(&block)
				@configuration.worker = block
			end
			
			def add_jobs_matching(klass, pattern: klass::PATTERN, **options)
				# This indicates that someone has added jobs:
				@configuration.loaded = true
				
				Dir.glob(pattern, base: @base) do |path|
					path = File.expand_path(path, @base)
					@configuration.jobs << [klass, path, **options]
				end
			end
			
			def defaults!
				DEFAULT_JOB_CLASSES.each do |klass|
					add_jobs_matching(klass)
				end
			end
		end
	end
end
