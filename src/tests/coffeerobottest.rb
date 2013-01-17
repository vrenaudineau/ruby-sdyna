# encoding: utf-8

require 'test/unit'
require_relative "../data/variable"
require_relative "../sdyna"
require_relative "./coffeerobot"

module SDYNA
	class CoffeeRobotTest < Test::Unit::TestCase		
		def test1
			loop = 1000
			robot = CoffeeRobot.new
			verbose = true
			
			robot.run(loop, robot.newInitState, verbose)
			
			#### TESTS ####
			pol = robot.fmdp.policy
			puts robot.fmdp, pol
			assert pol[robot.hrc=>true, robot.off=>true, robot.umb=>true].content == "del"
			assert pol[robot.hrc=>false, robot.off=>false, robot.umb=>true].content == "buy"
			
			return robot
		end
		
		def test2
			loop = 20
			perLoop = 50
			robot = CoffeeRobot.new
			verbose = true
			
			robot.run2(loop, perLoop, verbose)
			
			#### TESTS ####
			pol = robot.fmdp.policy
			puts robot.fmdp, pol
			assert pol[robot.hrc=>true, robot.off=>true, robot.umb=>true].content == "del"
			assert pol[robot.hrc=>false, robot.off=>false, robot.umb=>true].content == "buy"
			
			return robot
		end
	end
end
