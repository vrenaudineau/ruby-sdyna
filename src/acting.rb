# encoding: utf-8

require_relative "./data/fmdp"

module SDYNA
	# See Acting.act.
	module Acting		
		# Like greedy politic, but return a random action with a probability of epsilon.
		def self.e_greedy(fmdp, currentState, epsilon)
			if rand() < epsilon
				return fmdp.actions.sample
			else
				return greedy(fmdp, currentState)
			end
		end
		
		# Return the action which maximize the esperance.
		def self.greedy(fmdp, currentState)
			list = []
			max = (-1.0/0) # -Inf
			fmdp.actions.each do |a|
				v = (if ! fmdp.q[a].nil? then fmdp.q[a][currentState].content else 0 end)
				if v > max
					list = [a]
					max = v
				elsif v == max
					list << a
				end
			end
			a = list.sample
			return a
		end
	end # module Acting
end # module SDYNA
