
require 'stringio'

module Enumerable
	def sum
		self.inject(0){|accum, i| accum + i }
	end

	def mean
		self.sum/self.length.to_f
	end

	def sample_variance
		m = self.mean
		sum = self.inject(0){|accum, i| accum +(i-m)**2 }
		sum/(self.length - 1).to_f
	end

	def standard_deviation
		return Math.sqrt(self.sample_variance)
	end
	
	def standard_error
		return standard_deviation / Math.sqrt(self.length)
	end
end 

class Trial
	def initialize
		@targets = {}
	end
	
	def add_event(marker, time)
		@targets[marker] ||= []
		@targets[marker] << time
	end
	
	def inspect
		buffer = StringIO.new
		
		@targets.each do |marker, times|
			buffer.puts "\t#{marker}: Mean: #{times.mean} SD: #{times.standard_deviation} SE: #{times.standard_error}"
		end
		
		return buffer.string
	end
end


