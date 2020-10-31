
require 'rspec/support'
require 'rspec/core/formatters'

module TurboTest
	module RSpec
		class ExampleFormatter
			::RSpec::Core::Formatters.register self, :example_finished, :example_failed, :dump_summary
			
			def initialize(packer)
				@packer = packer
				
				@colorizer = ::RSpec::Core::Formatters::ConsoleCodes
			end
			
			def output
				@packer
			end
			
			def example_finished(notification)
				@packer.write([:finished, notification.example.id])
				@packer.flush
			end
			
			def example_failed(notification)
				example = notification.example
				
				presenter = ::RSpec::Core::Formatters::ExceptionPresenter.new(example.exception, example)
				
				message = {
					description: example.full_description,
					location: example.location_rerun_argument,
					report: presenter.fully_formatted(nil, @colorizer),
				}
				
				@packer.write([:failed, message])
				@packer.flush
			end
			
			def dump_summary(summary)
				count = summary.examples.count
				
				@packer.write([:count, count])
				@packer.flush
			end
		end
	end
end

