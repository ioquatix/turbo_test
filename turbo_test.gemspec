# frozen_string_literal: true

require_relative "lib/turbo_test/version"

Gem::Specification.new do |spec|
	spec.name = "turbo_test"
	spec.version = TurboTest::VERSION
	
	spec.summary = "Press the turbo button... for your tests."
	spec.authors = ["Samuel Williams"]
	spec.license = "MIT"
	
	spec.cert_chain  = ['release.cert']
	spec.signing_key = File.expand_path('~/.gem/release.pem')
	
	spec.homepage = "https://github.com/ioquatix/turbo_test"
	
	spec.metadata = {
		"funding_uri" => "https://github.com/sponsors/ioquatix/",
	}
	
	spec.files = Dir.glob(['{bin,lib}/**/*', '*.md'], File::FNM_DOTMATCH, base: __dir__)
	
	spec.executables = ["turbo_test"]
	
	spec.required_ruby_version = ">= 2.3.0"
	
	spec.add_dependency "async-container"
	spec.add_dependency "async-io"
	spec.add_dependency "msgpack"
	spec.add_dependency "rspec"
	spec.add_dependency "samovar"
end
