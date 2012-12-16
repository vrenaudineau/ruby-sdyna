# encoding: utf-8

require 'test/unit'
require_relative "../src/fmdp"

module SDYNA
	class CoffeeTest < Test::Unit::TestCase
		def test_value(fmdp = nil)
			if fmdp.nil?
				fmdp = test_coffee_robot(false) 
				#~ fmdp = test_easy_coffee(false) 
				fmdp.valeur = fmdp.recompenses
				puts fmdp, fmdp.valeur
			end
			c = nil
			begin
				tStart = Time.now
				case c
					when "q"
						break
					when "p"
						puts "Politique :", fmdp.politique
					when "r"
						puts "Recompences :", fmdp.recompenses
					when "a"
						fmdp.q.each do |a,t|
							puts "For #{a}", t
						end
					else
						fmdp.incSVI()
						puts fmdp.valeur
				end
				tEnd = Time.now
				print "[%dms] quit ? (q or try also p/r/a) : " % ((Time.now - tStart) * 1000)
				c = gets.chop
			end while c != "q"
			return fmdp
		end
		
		def test_easy_coffee(verbose = true)
			off = Variable.new("off", [true, false])
			hoc = Variable.new("hoc", [true, false])
			hrc = Variable.new("hrc", [true, false])
			
			fmdp = FMDP.new( {
				"off" => [true,false],
				"hoc" => [true,false],
				"hrc" => [true,false]
			}, ["go","buy","del"] )
			
			currentState = {
				"off" => true,
				"hoc" => false,
				"hrc" => false
			}
			
			def doAct(s, a)
				newState = s.clone
				r = 0
				r += 10 if s["hoc"]
				newState["hoc"] = false
				case a
					when "go"
						newState["off"] = ! s["off"]
					when "buy"
						newState["hrc"] = (s["hrc"] || ! s["off"])
					when "del"
						newState["hrc"] = false
						newState["hoc"] = s["off"] && s["hrc"]
				end
				return newState, r
			end
			
			fmdp.epsilon = 20
			n = 500
			print sprintf("%2d%%",1) #if verbose
			for i in 1..n
				action = fmdp.act(currentState)
				newState, r = doAct(currentState, action)
				fmdp.observe(currentState, action, newState, r)
				currentState = newState
				#~ if verbose
					print "\b\b\b", sprintf("%2d%%",i*100/n) 
					$stdout.flush
				#~ end
			end
			puts "\b\b\b\b" #if verbose
			if verbose
				puts fmdp, fmdp.valeur
				for a, qa in fmdp.q
					puts "For #{a} :", qa
				end
			end
						
			#### TESTS ####
			pol = fmdp.politique
			assert pol[hrc=>true, off=>true].content == "del"
			assert pol[hrc=>true, off=>false].content == "go"
			assert pol[hrc=>false, off=>false].content == "buy"
			assert pol[hrc=>false, off=>true].content == "go"
			
			return fmdp
		end
		
		def test_coffee_robot(verbose = true)
			wet = Variable.new("wet", [true, false])
			umb = Variable.new("umb", [true, false])
			rain = Variable.new("rain", [true, false])
			off = Variable.new("off", [true, false])
			hoc = Variable.new("hoc", [true, false])
			hrc = Variable.new("hrc", [true, false])
			
			fmdp = FMDP.new( {
				"wet" => [true,false],
				"umb" => [true,false],
				"rain" => [true,false],
				"off" => [true,false],
				"hoc" => [true,false],
				"hrc" => [true,false]
			}, ["go","buy","del","getU"] )
			
			currentState = {
				"wet" => false,
				"umb" => false,
				"rain" => false,
				"off" => true,
				"hoc" => false,
				"hrc" => false
			}
			
			def doAct( s, a )
				newState = s.clone
				newState["rain"] = (rand() > 0.4)
				newState["hoc"] = false
				newState["wet"] = (s["wet"] && (rand() < 0.8)) # 20% de chance de sécher
				
				r = 0
				r += 1 if ! s["wet"]
				r += 9 if s["hoc"]
				
				case a
					when "go"
						newState["off"] = ! s["off"]
						newState["wet"] = newState["wet"] || (s["rain"] && ! s["umb"])
					when "buy"
						newState["hrc"] = (s["hrc"] || ! s["off"])
					when "del"
						newState["hrc"] = false
						newState["hoc"] = s["off"] && s["hrc"]
					when "getU"
						newState["umb"] = ! s["umb"] if s["off"]
				end
				
				return newState, r
			end
			
			fmdp.epsilon = 20
			n = 500
			print sprintf("%2d%%",1)# if verbose
			for i in 1..n
				action = fmdp.act(currentState)
				newState, r = doAct(currentState, action)
				#~ p( [currentState,action,newState, r] )
				fmdp.observe(currentState, action, newState, r)
				currentState = newState
				#~ if verbose
					print "\b\b\b", sprintf("%2d%%",i*100/n)
					$stdout.flush
				#~ end
			end
			puts "\b\b\b\b"# if verbose
			if verbose
				puts "\b\b\b\b"
				puts fmdp, fmdp.valeur
				for a, qa in fmdp.q
					puts "For #{a} :", qa
				end
			end
			
			#### TESTS ####
			pol = fmdp.politique
			assert pol[hrc=>true, off=>true].content == "del"
			assert pol[hrc=>true, off=>false].content == "go"
			assert pol[hrc=>false, off=>false].content == "buy"
			assert pol[hrc=>false, off=>true, umb=>true].content == "go"
			assert pol[hrc=>false, off=>true, umb=>false].content == "getU"
			
			return fmdp			
		end # def test_coffee_robot
	end # class CoffeeTest
end # module SDYNA
