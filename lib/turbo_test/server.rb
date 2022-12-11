# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2022, by Samuel Williams.

require 'async'
require 'async/container'
require 'async/io/unix_endpoint'
require 'async/io/shared_endpoint'

require 'async/io/threads'

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
			@endpoint = endpoint || Async::IO::Endpoint.unix("turbo_test-#{Process.pid}.ipc")
			@wrapper = Wrapper.new
			
			@container = Async::Container.new
		end
		
		def host(queue)
			input, output = IO.pipe
			input.binmode
			output.binmode
			
			@container.spawn(name: "#{self.class} Host") do |instance|
				connected = 0
				progress = Console.logger.progress("Queue", queue.size)
				failures = []
				
				statistics = {
					succeeded: 0,
					failed: 0,
				}
				
				Async do |task|
					bound_endpoint = Sync do
						Async::IO::SharedEndpoint.bound(@endpoint)
					end
					
					instance.ready!
					
					bound_endpoint.accept do |peer|
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
								statistics[:failed] += 1
							when :count
								Console.logger.debug("Job Count") {arguments}
								statistics[:succeeded] += arguments.first
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
					
					bound_endpoint.close
				end
			ensure
				Console.logger.info("Writing results")
				@wrapper.packer(output).write(statistics).flush
			end
			
			output.close
			
			return @wrapper.unpacker(input)
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
					sleep(rand)
					@endpoint.connect do |peer|
						threads = Async::IO::Threads.new
						
						packer = @wrapper.packer(peer)
						unpacker = @wrapper.unpacker(peer)
						
						packer.write([:ready])
						packer.flush
						
						instance.ready!
						
						unpacker.each do |message|
							command, tail = message
							
							case command
							when :connected
								@configuration&.worker&.call(*tail)
							when :job
								klass, *arguments = *tail
								
								begin
									# We run this in a separate thread to keep it isolated from the worker loop:
									result = threads.async do
										klass.new(*arguments).call(packer: packer)
									end.wait
									
									packer.write([:result, result])
								rescue Exception => exception
									packer.write([:error, exception.class, exception.backtrace])
								end
								
								packer.write([:ready])
								packer.flush
							else
								Console.logger.warn(self) {"Unhandled command: #{command}#{arguments.inspect}"}
							end
						end
					end
				rescue Errno::ECONNREFUSED
					# Host is finished already.
				end
			end
		end
		
		def run(queue)
			# Start the host:
			results = self.host(queue)
			
			# Wait until the host is ready:
			@container.wait_until_ready
			
			# Start the workers:
			self.workers
			
			# Wait for the container to finish:
			@container.wait
			
			# Read the results from the host:
			return results.read
		ensure
			if path = @endpoint.path and File.exist?(path)
				File.unlink(path)
			end
		end
	end
end
