
require_relative "lib/turbo_test/version"

Gem::Specification.new do |spec|
	spec.name = "turbo_test"
	spec.version = TurboTest::VERSION
	
	spec.summary = "Press the turbo button... for your tests."
	spec.authors = ["Samuel Williams"]
	spec.license = "MIT"
	
	spec.homepage = "https://github.com/ioquatix/turbo_test"
	
	spec.metadata = {
		"funding_uri" => "https://github.com/sponsors/ioquatix/",
	}
	
	spec.files = Dir.glob('{bin,lib}/**/*', File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 2.3.0"
	
	spec.add_dependency "async-container"
	spec.add_dependency "async-io"
	spec.add_dependency "msgpack"
	spec.add_dependency "rspec"
end