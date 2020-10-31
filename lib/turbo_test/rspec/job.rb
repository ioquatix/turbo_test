
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
				options = ConfigurationOptions.new([@path],
					packer: packer
				)
				
				runner = ::RSpec::Core::Runner.new(options)
				
				runner.run(stdout, stderr)
			end
		end
	end
end
