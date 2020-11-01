
module TurboTest
	class Configuration
		def initialize
			@worker = nil
		end
		
		attr_accessor :worker
		
		def self.load(path)
			configuration = self.new
			
			loader = Loader.new(configuration)
			loader.instance_eval(File.read(path), path.to_s)
			
			return configuration
		end
		
		class Loader
			def initialize(configuration)
				@configuration = configuration
			end
			
			def worker(&block)
				@configuration.worker = block
			end
		end
	end
end
