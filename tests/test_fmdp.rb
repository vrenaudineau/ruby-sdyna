# encoding: utf-8

require 'test/unit'
require_relative "../src/node"
require_relative "../src/fmdp"

module SDYNA
	class FMDPTest < Test::Unit::TestCase
		def test_working_initialize
			assert_nothing_raised do
				FMDP.new({"v1"=>[true,false],
					"v2"=>[1,2,3],
					"v3"=>[:bas,:mileu,:haut],
					"v4"=>["rouge","bleu","vert"]},
					%w{a1 a2 a3})
			end
		end		
		def test_p_regress
			x = Variable.new("x", [:true, :false])
			y = Variable.new("y", [:true, :false])
			z = Variable.new("z", [:true, :false])

			# Tree[V^1]
			v = Tree.from_hash({
				z => {:false => {y => {:true  => 8.1,
									   :false => 0}},
					  :true  => 19}})
			# Tree[P[Z']]
			pz = Tree.from_hash({
				z => {:false => {y => {:true  => {:pot => {z=>{:true=>0.9,:false=>0.1}}},
									   :false => {:pot => {z=>{:true=>0.0,:false=>1.0}}}}},
					  :true  => {:pot => {z=>{:true=>1.0,:false=>0.0}}}}})		
			# Tree[P[Y']]
			py = Tree.from_hash({
				y => {:false => {x => {:true  => {:pot => {y=>{:true=>0.9,:false=>0.1}}},
									   :false => {:pot => {y=>{:true=>0.0,:false=>1.0}}}}},
					  :true  => {:pot => {y=>{:true=>1.0,:false=>0.0}}}}})
			
			normalResult = Tree.from_hash({
				z => {:false => {y => {:true  => {:pot => {z=>{:true=>0.9,:false=>0.1},y=>{:true=>1.0,:false=>0.0}}},
									   :false => {x => {:true  => {:pot => {z=>{:true=>0.0,:false=>1.0},y=>{:true=>0.9,:false=>0.1}}},
														:false => {:pot => {z=>{:true=>0.0,:false=>1.0},y=>{:true=>0.0,:false=>1.0}}}}}}},
					  :true  => {:pot => {z=>{:true=>1.0,:false=>0.0}}}}})
			
			fmdp = FMDP.new( {"x"=>[:true, :false], "y"=>[:true, :false], "z"=>[:true, :false]}, [:a] )
			fmdp.transitions[:a][z] = pz
			fmdp.transitions[:a][y] = py
			fmdp.valeur = v
			
			result = nil
			assert_nothing_raised do
				result = fmdp.p_regress( v, :a ).simplify!
			end
			
			assert normalResult == result, "result=\n#{result}\nnormal result=\n#{normalResult}"
		end
		
		def test_regress
			x = Variable.new("x", [:true, :false])
			y = Variable.new("y", [:true, :false])
			z = Variable.new("z", [:true, :false])
			
			# MyTree[V^1]
			v = Tree.from_hash({
				z => {:false=> {y => {:true => 8.1,
									  :false=> 0}},
					  :true => 19}})
			
			# MyTree[P[Z']]
			pz = Tree.from_hash({
				z => {:false=> {y => {:true => {:pot => {z=>{:true=>0.9,:false=>0.1}}},
									  :false=> {:pot => {z=>{:true=>0.0,:false=>1.0}}}}},
					  :true => {:pot => {z=>{:true=>1.0,:false=>0.0}}}}})
			
			# MyTree[P[Y']]
			py = Tree.from_hash({
				y => {:false=> {x => {:true => {:pot => {y=>{:true=>0.9,:false=>0.1}}},
									  :false=> {:pot => {y=>{:true=>0.0,:false=>1.0}}}}},
					  :true => {:pot => {y=>{:true=>1.0,:false=>0.0}}}}})
			
			# MyTree[R]
			r = Tree.from_hash({
				z => {:true => 10,
					  :false=> 0}})
			
			normalResult = Tree.from_hash({
				z => {:false=> {y => {:true => 16.119,
									  :false=> {x => {:true => 6.561,
													  :false=> 0.0}}}},
					  :true => 27.1}})
			
			fmdp = FMDP.new( {"x"=>[:true, :false], "y"=>[:true, :false], "z"=>[:true, :false]}, [:a] )
			fmdp.transitions[:a][z] = pz
			fmdp.transitions[:a][y] = py
			fmdp.valeur = v
			fmdp.recompenses = r
			
			result = nil
			assert_nothing_raised do
				result = fmdp.regress( :a )
			end
			assert result == normalResult, "result=\n#{result}\nnormal result=\n#{normalResult}"
		end # test_regress
		
		def test_regress2
			x = Variable.new("x", [:true, :false])
			y = Variable.new("y", [:true, :false])
			z = Variable.new("z", [:true, :false])
			
			# Tree[P[Z']]
			pz = Tree.from_hash({
				z => {:false=> {y => {:true => {:pot=>{z=>{:true=>0.9,:false=>0.1}}},
									  :false=> {:pot=>{z=>{:true=>0.0,:false=>1.0}}}}},
					  :true => {:pot=>{z=>{:true=>1.0,:false=>0.0}}}}})
			
			# Tree[P[Y']]
			py = Tree.from_hash({
				y => {:false=> {x => {:true => {:pot=>{y=>{:true=>0.9,:false=>0.1}}},
									  :false=> {:pot=>{y=>{:true=>0.0,:false=>1.0}}}}},
					  :true => {:pot=>{y=>{:true=>1.0,:false=>0.0}}}}})
			
			# Tree[R]
			r = Tree.from_hash({
				z => {:true => 10,
					   :false=> 0}})
			
			normalResult = Tree.from_hash({
				z => {:false=> {y => {:true => 16.119,
									  :false=> {x => {:true => 6.561,
													  :false=> 0.0}}}},
					   :true => 27.1}})
			
			fmdp = FMDP.new( {
				"x" => [:true,:false],
				"y" => [:true,:false],
				"z" => [:true,:false]
			}, [:a] )
			fmdp.transitions[:a][z] = pz
			fmdp.transitions[:a][y] = py
			fmdp.valeur = r.clone
			fmdp.recompenses = r
			
			result = nil
			assert_nothing_raised do
				fmdp.valeur = fmdp.regress( :a )
				result = fmdp.regress(:a)
			end
			assert result == normalResult, "result=\n#{result}\nnormal result=\n#{normalResult}"
		end # regress2
		
		def test_update_tree_s
			x = Variable.new("x", [:true, :false])
			y = Variable.new("y", [:true, :false])
			z = Variable.new("z", [:true, :false])
			
			# Tree[P[Z']]
			pz = Tree.from_hash({
				z => {:false=> {y => {:true => {:pot=>{z=>{:true=>0.9,:false=>0.1}}},
									  :false=> {:pot=>{z=>{:true=>0.0,:false=>1.0}}}}},
					  :true => {:pot=>{z=>{:true=>1.0,:false=>0.0}}}}})
			
			# Tree[P[Y']]
			py = Tree.from_hash({
				y => {:false=> {x => {:true => {:pot=>{y=>{:true=>0.9,:false=>0.1}}},
									  :false=> {:pot=>{y=>{:true=>0.0,:false=>1.0}}}}},
					  :true => {:pot=>{y=>{:true=>1.0,:false=>0.0}}}}})
			
			# Tree[R]
			r = Tree.from_hash({
				z => {:true => 10,
					   :false=> 0}})
			
			normalResult = Tree.from_hash({
				z => {:false=> {y => {:true => 16.119,
									  :false=> {x => {:true => 6.561,
													  :false=> 0.0}}}},
					   :true => 27.1}})
			
			fmdp = FMDP.new( {
				"x" => [:true,:false],
				"y" => [:true,:false],
				"z" => [:true,:false]
			}, [:a] )
			fmdp.transitions[:a][z] = pz
			fmdp.transitions[:a][y] = py
			fmdp.valeur = r.clone
			fmdp.recompenses = r
			fmdp.epsilon = 1
			
			
			fmdp.update_tree_s(fmdp.transitions[:a][z], z, Exemple.new({x=>:false,y=>:true,z=>:true}, :false))
			assert fmdp.transitions[:a][z].leaf?
			fmdp.update_tree_s(fmdp.transitions[:a][z], z, Exemple.new({x=>:false,y=>:false,z=>:true}, :false))
			assert fmdp.transitions[:a][z].leaf?
			fmdp.update_tree_s(fmdp.transitions[:a][z], z, Exemple.new({x=>:true,y=>:true,z=>:true}, :true))
			assert ! fmdp.transitions[:a][z].leaf? && fmdp.transitions[:a][z].test?(x)
		end
		
		def test_coffee_robot
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
			}, ["go","buy","del","getU","wait"] )
			
			fmdp.valeur = Tree.from_hash({
				hoc => {false=> 0,
						true => 1}})
			
			currentState = {
				"wet" => false,
				"umb" => false,
				"rain" => false,
				"off" => true,
				"hoc" => false,
				"hrc" => false
			}
			fmdp.epsilon = 10
			
			def doAct( s, a )
				newState = s.clone
				r = 0
				case a
				when "go"
					newState["off"] = ! s["off"]
					newState["wet"] = s["wet"] || (s["rain"] && ! s["umb"])
				when "buy"
					newState["hrc"] = s["hrc"] || ! s["off"]
				when "del"
					newState["hoc"] = false
					# Si le robot à un café et est au bureau
					if s["off"] && s["hrc"]
						newState["hoc"] = rand() < 0.8 # 80% de chance qu'il arrive à lui donner
						newState["hrc"] = ! newState["hoc"] # Echange de main
					end
				when "getU"
					newState["umb"] = ! s["umb"] if s["off"]
				end
				newState["rain"] = (rand() > 0.4)
				newState["hoc"] = false unless a == "del" # il a bu son café
				newState["wet"] = s["wet"] && (rand() < 0.8) unless a == "go" && s["rain"] && ! s["umb"] # 20% de chance de sécher
				
				r += 1 if ! newState["wet"]
				r += 9 if newState["hoc"]
				
				return newState, r
			end
			
			i = 0
			n = 1000
			print sprintf("%2d%%",i)
			while i < n
				action = fmdp.act(currentState)
				newState, r = doAct(currentState, action)
				fmdp.observe(currentState, action, newState, r)
				currentState = newState
				i+= 1
				print "\b\b\b"
				print sprintf("%2d%%",i*100/n)
				$stdout.flush
			end
			p( [currentState, action, newState, r] )
			puts fmdp
			
			#~ result = nil
			#~ normalResult = nil
			#~ raise "result=\n#{result}\nnormal result=\n#{normalResult}" if result != normalResult
		end # coffeeRobot
	end
end
