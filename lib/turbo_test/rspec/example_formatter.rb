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

