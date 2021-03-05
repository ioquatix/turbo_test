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
