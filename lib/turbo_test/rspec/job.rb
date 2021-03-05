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

require 'rspec/core'

require_relative 'example_formatter'

module TurboTest
	module RSpec
		class ConfigurationOptions < ::RSpec::Core::ConfigurationOptions
			def initialize(arguments, packer:)
				super(arguments)
				
				@packer = packer
			end
				
			def configure(config)
				super(config)
				
				config.add_formatter(ExampleFormatter.new(@packer))
			end
			
			def load_formatters_into(config)
				# Don't load any formatters, default or otherwise.
			end
		end
		
		class Job
			PATTERN = "spec/**/*_spec.rb"
			
			def initialize(path, **options)
				@path = path
			end
			
			def call(packer:, stdout: $stdout, stderr: $stderr)
				reset_rspec_state!
				
				options = ConfigurationOptions.new([@path],
					packer: packer
				)
				
				runner = ::RSpec::Core::Runner.new(options)
				
				runner.run(stdout, stderr)
			end
			
			private
			
			def reset_rspec_state!
				::RSpec.clear_examples
				
				# see https://github.com/rspec/rspec-core/pull/2723
				if Gem::Version.new(::RSpec::Core::Version::STRING) <= Gem::Version.new("3.9.1")
					::RSpec.world.instance_variable_set(
						:@example_group_counts_by_spec_file, Hash.new(0)
					)
				end
				
				# RSpec.clear_examples does not reset those, which causes issues when
				# a non-example error occurs (subsequent jobs are not executed)
				# TODO: upstream
				::RSpec.world.non_example_failure = false
				
				# we don't want an error that occured outside of the examples (which
				# would set this to `true`) to stop the worker
				::RSpec.world.wants_to_quit = false
			end
		end
	end
end
