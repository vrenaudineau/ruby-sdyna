# encoding: utf-8

require 'test/unit'
require_relative "../data/variable"
require_relative "../sdyna"

module SDYNA
	class EasyCoffeeRobotTest < Test::Unit::TestCase
		class EasyCoffeeRobot < Sdyna
			attr_reader :off, :hoc, :hrc
			
			def initialize
				@off = Variable.new("off", [true, false])
				@hoc = Variable.new("hoc", [true, false])
				@hrc = Variable.new("hrc", [true, false])
				@actions = ["go","buy","del"]
				super([@off, @hoc, @hrc], @actions)
				
				@epsilon4greedy = 0.3
				@rewardDependsOfAction = false
				@gamma4incSVI = 0.9
				@diffEpsilon4chiSquare = 20
				@reorganiseValue = false
			end
			
			def exec(s, a, verbose)
				newState = s.clone
				r = 0
				r += 10 if s[@hoc]
				newState[@hoc] = false
				case a
					when "go"
						newState[@off] = ! s[@off]
					when "buy"
						newState[@hrc] = (s[@hrc] || ! s[@off])
					when "del"
						newState[@hrc] = false
						newState[@hoc] = s[@off] && s[@hrc]
				end
				return newState, r
			end
			
			def newInitState
				return {
					@off => rand() < 0.5,
					@hoc => rand() < 0.2,
					@hrc => rand() < 0.3
				}
			end
		end
		
		def test
			n = 500
			robot = EasyCoffeeRobot.new
			verbose = true
			currentState = {
				robot.off => true,
				robot.hoc => false,
				robot.hrc => false
			}
			
			robot.run(n, currentState, verbose)
					
			#### TESTS ####
			pol = robot.fmdp.policy
			#~ puts robot.fmdp, pol
			assert pol[robot.hrc=>true, robot.off=>true].content == "del"
			assert pol[robot.hrc=>true, robot.off=>false].content == "go"
			assert pol[robot.hrc=>false, robot.off=>false].content == "buy"
			assert pol[robot.hrc=>false, robot.off=>true].content == "go"
			
			return robot
		end
	end
end
