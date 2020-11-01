
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
			def initialize(path)
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
