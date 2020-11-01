
require 'async'
require 'async/container'
require 'async/io/unix_endpoint'
require 'async/io/shared_endpoint'
require 'msgpack'

module TurboTest
	class Wrapper < MessagePack::Factory
		def initialize
			super()
			
			# self.register_type(0x00, Object, packer: @bus.method(:temporary), unpacker: @bus.method(:[]))
			
			self.register_type(0x01, Symbol)
			self.register_type(0x02, Exception,
				packer: ->(exception){Marshal.dump(exception)},
				unpacker: ->(data){Marshal.load(data)},
			)
			
			self.register_type(0x03, Class,
				packer: ->(klass){Marshal.dump(klass)},
				unpacker: ->(data){Marshal.load(data)},
			)
		end
	end
	
	class Server
		def initialize(configuration, endpoint = nil)
			@configuration = configuration
			@endpoint = endpoint || Async::IO::Endpoint.unix('turbo_test.ipc')
			@wrapper = Wrapper.new
			
			@container = Async::Container.new
			
			@bound_endpoint = Sync do
				Async::IO::SharedEndpoint.bound(@endpoint)
			end
		end
		
		def host(queue)
			@container.spawn(name: "#{self.class} Host") do |instance|
				connected = 0
				progress = Console.logger.progress("Queue", queue.size)
				failures = []
				
				Async do |task|
					instance.ready!
					
					@bound_endpoint.accept do |peer|
						# Console.logger.info(self) {"Incoming connection from #{peer}..."}
						
						packer = @wrapper.packer(peer)
						unpacker = @wrapper.unpacker(peer)
						
						packer.write([:connected, connected])
						connected += 1
						
						unpacker.each do |message|
							command, *arguments = message
							
							case command
							when :ready
								Console.logger.debug("Child Ready") {arguments}
								
								if job = queue.pop
									packer.write([:job, job])
									packer.flush
								else
									Console.logger.debug("Child Closed")
									peer.close_write
									connected -= 1
									
									if connected.zero?
										print_summary(failures)
										task.stop
									end
								end
							when :finished
								Console.logger.debug("Job Finished") {arguments}
							when :failed
								Console.logger.debug("Job Failed") {arguments}
								failures << arguments
							when :count
								Console.logger.debug("Job Count") {arguments}
							when :result
								Console.logger.debug("Job Result") {arguments}
								progress.increment
							when :error
								Console.logger.error("Job Error") {arguments}
							else
								Console.logger.warn(self) {"Unhandled command: #{command}#{arguments.inspect}"}
							end
						end
					end
				end
			end
		end
		
		def print_summary(failures, command = $0)
			return unless failures.any?
			
			failures.sort_by!{|(failure)| failure[:location]}
			
			$stderr.puts nil, "Failures:", nil
			
			failures.each do |(failure)|
				$stderr.puts failure[:report]
				$stderr.puts
			end
			
			$stderr.puts nil, "Summary:", nil
			
			failures.each do |(failure)|
				$stderr.puts "#{command} #{failure[:location]} \# #{failure[:description]}"
			end
			
			$stderr.puts
		end
		
		def workers
			@container.run(name: "#{self.class} Worker") do |instance|
				Async do |task|
					@endpoint.connect do |peer|
						instance.ready!
						
						packer = @wrapper.packer(peer)
						unpacker = @wrapper.unpacker(peer)
						
						packer.write([:ready])
						packer.flush
						
						unpacker.each do |message|
							command, tail = message
							
							case command
							when :connected
								@configuration.worker&.call(*tail)
							when :job
								klass, *arguments = *tail
								
								begin
									result = klass.new(*arguments).call(packer: packer)
									packer.write([:result, result])
								rescue Exception => exception
									packer.write([:error, exception, exception.backtrace])
								end
								
								packer.write([:ready])
								packer.flush
							else
								Console.logger.warn(self) {"Unhandled command: #{command}#{arguments.inspect}"}
							end
						end
					end
				end
			end
		end
		
		def wait
			@container.wait
		end
	end
end
