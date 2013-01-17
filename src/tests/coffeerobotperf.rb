# encoding: utf-8

require_relative "../data/variable"
require_relative "../sdyna"
require_relative "./coffeerobot"

module SDYNA
	class CoffeeRobotPerf
		def self.test1
			loop = 1000
			robot = CoffeeRobot.new
			verbose = true
			
			robot.run(loop, robot.newInitState, verbose)
			
			return robot
		end
		
		def self.test2
			loop = 20
			perLoop = 50
			robot = CoffeeRobot.new
			verbose = true
			
			robot.run2(loop, perLoop, verbose)
			
			return robot
		end
		
		def self.perf(n=1)
			print "Start Perf Test : "
			
			results = {:test1=>[], :test2=>[]}
			n.times do
				print "."
				startTime = Time.now
				robot1 = test1()
				endTime = Time.now
				results[:test1] << endTime-startTime
				
				startTime = Time.now
				robot2 = test2()
				endTime = Time.now
				results[:test2] << endTime-startTime
			end
			puts
			
			for test, r in results
				puts "### #{test} ###"
				puts "Results : #{r.inspect}"
				m = (r.inject :+)/r.size
				puts "Mean : #{m}"
				v = Math.sqrt(r.collect { |t| (t-m)**2 }.inject :+)
				puts "Var : #{v}"
			end
			
			puts "Perf Test Ended !"
		end
	end
end

SDYNA::CoffeeRobotPerf.perf(ARGV[0].to_i) if $0 == __FILE__
