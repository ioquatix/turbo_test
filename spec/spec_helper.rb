# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2022, by Samuel Williams.

require "bundler/setup"
require "turbo_test"

RSpec.configure do |config|
	# Enable flags like --only-failures and --next-failure
	config.example_status_persistence_file_path = ".rspec_status"

	# Disable RSpec exposing methods globally on `Module` and `main`
	config.disable_monkey_patching!

	config.expect_with :rspec do |c|
		c.syntax = :expect
	end
end
