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
			input, output = IO.pipe
			
			@container.spawn(name: "#{self.class} Host") do |instance|
				connected = 0
				progress = Console.logger.progress("Queue", queue.size)
				failures = []
				
				statistics = {
					succeeded: 0,
					failed: 0,
				}
				
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
								@configuration&.worker&.call(*tail)
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
