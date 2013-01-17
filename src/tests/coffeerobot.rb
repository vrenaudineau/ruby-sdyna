# encoding: utf-8

require_relative "../data/variable"
require_relative "../sdyna"

module SDYNA
	class CoffeeRobot < Sdyna
		attr_reader :off, :hoc, :hrc, :umb, :wet, :rain
		
		def initialize
			@off = Variable.new("off", [true, false])
			@hoc = Variable.new("hoc", [true, false])
			@hrc = Variable.new("hrc", [true, false])
			@umb = Variable.new("umb", [true, false])
			@wet = Variable.new("wet", [true, false])
			@rain = Variable.new("rain", [true, false])
			@actions = ["go", "buy", "del", "umb"]
			super([@off, @hoc, @hrc, @umb, @wet, @rain], @actions)
			
			@epsilon4greedy = 0.3
			@rewardDependsOfAction = false
			@gamma4incSVI = 0.9
			@diffEpsilon4chiSquare = 30
			@reorganiseValue = false
		end
		
		def exec(s, a, verbose)
			newState = s.clone
			r = 0
			r += 9 if s[@hoc]
			r += 1 if ! s[@wet]
			newState[@hoc] = false
			newState[@wet] &&= rand() < 0.8 # 80% de chance de rester mouiller
			newState[@rain] = rand() < 0.4 # 40% de chance qu'il pleuve
			case a
				when "go"
					newState[@off] = ! s[@off]
					# Devient mouillé si il pleuvait et qu'il n'avait pas le parapluie.
					newState[@wet] ||= s[@rain] && ! s[@umb]
				when "buy"
					newState[@hrc] = (s[@hrc] || ! s[@off])
				when "del"
					newState[@hrc] = false
					newState[@hoc] = s[@off] && s[@hrc]
				when "umb"
					newState[@umb] = ! s[@umb] if s[@off]
			end
			return newState, r
		end
		
		def newInitState
			newState = {
				@off => rand() < 0.5,
				@hoc => rand() < 0.3,
				@hrc => rand() < 0.3,
				@umb => rand() < 0.0,
				@wet => rand() < 0.0,
				@rain => rand() < 0.5
			}
			return newState
		end
	end
end
