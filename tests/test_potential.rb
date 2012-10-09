# encoding: utf-8

require 'test/unit'
require_relative "../src/potential"

module SDYNA
	class PotentialTest < Test::Unit::TestCase
	
		V1 = Variable.new( "hoc", [true, false] )
		V2	= Variable.new( "weather", ["sunny","cloudy","rainy"] )
		V3	= Variable.new( "hrc", [true,false] )
		
		def test_potential1
			p1, p2 = [nil]*2
			assert_nothing_raised do
				p1 = Potential.new
			end
			# test []=
			assert_raise ArgumentError do
				p1[V1] = {true=>0.3, false=>0.6}
			end
			assert_nothing_raised do
				p1[V1] = {false=>0.6, true=>0.4}
			end
			assert_raise ArgumentError do
				p1[V1] = {true=>0.4, false=>0.6}
			end
			assert_raise ArgumentError do
				p1[V2] = {true=>0.3, false=>0.7}
			end
			assert_nothing_raised do
				p1[V2] = {"sunny"=>0.1, "rainy"=>0.4, "cloudy"=>0.5}
			end
			# test add
			assert_nothing_raised do
				p2 = Potential.new.add(V1, {true=>0.7, false=>0.3}).add(V2, {"sunny"=>0.4, "cloudy"=>0.25, "rainy"=>0.35})
			end
		end
		def test_potential2
			# test []
			p1 = Potential.new.add(V1, {true=>0.4,false=>0.6}).add(V2, {"sunny"=>0.1, "cloudy"=>0.4, "rainy"=>0.5})
			p2 = Potential.new.add(V2, {"sunny"=>0.1, "cloudy"=>0.4, "rainy"=>0.5}).add(V1, {true=>0.4,false=>0.6})
			p3 = Potential.new.add(V1, {true=>0.4,false=>0.6})
			p4 = Potential.new.add(V2, {"sunny"=>0.1, "cloudy"=>0.4, "rainy"=>0.5})
			
			i1 = Instanciation.from_hash({V1=>true, V2=>"sunny"})
			i2 = Instanciation.from_hash({V1=>false, V2=>"cloudy"})
			i3 = Instanciation.from_hash({V1=>false})
			#assert_in_delta((1.1-0.9), 0.2, 0.0001)
			assert_in_delta(p1[i1], 0.04, 0.001)
			assert_in_delta(p1[i2], 0.24, 0.001)
			assert_in_delta(p1[i3], 0.6, 0.001)
			assert_equal( {true=>0.4, false=>0.6}, p1[V1] )
			# test ==
			assert p1 == p2
			# test *
			assert p3*p4 == p2
		end
	end
end
