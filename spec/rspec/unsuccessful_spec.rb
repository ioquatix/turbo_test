# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2022, by Samuel Williams.

require 'turbo_test/command/run'

RSpec.describe TurboTest::Command::Run do
	let(:pattern) do
		File.expand_path("../../fixtures/rspec/spec/unsuccessful/**/*_spec.rb", __dir__)
	end
	
	let(:configuration_path) do
		File.expand_path("../../fixtures/rspec/turbo_test.rb", __dir__)
	end
	
	let(:command) do
		described_class[
			"--configuration", configuration_path,
			*Dir.glob(pattern)
		]
	end
	
	it "should report failed cases" do
		statistics = command.call
		
		expect(statistics[:failed]).to be == 1
	end
end
