# encoding: utf-8

require_relative "./variable"
require_relative "./potential"

module SDYNA
	#
	class Example
		attr_reader :state , :sigma
		#
		def initialize( state, sigma )
			@state, @sigma = state, sigma
		end
		#
		def to_s
			return "#{@state.inspect}=>#{sigma.inspect}"
		end
	end # class Example
end
