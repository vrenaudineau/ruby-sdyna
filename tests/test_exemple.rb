# encoding: utf-8

require 'test/unit'
require_relative "../src/exemple"

module SDYNA
	class ExempleTest < Test::Unit::TestCase
		def test_exemples
			x = Variable.new("x", [true,false])
			y = Variable.new("y", [true,false])
			
			e1 = Exemple.new( {x=>true,y=>false}, 0.0 )
			e2 = Exemple.new( {x=>false,y=>true}, 4.0 )
			e3 = Exemple.new( {x=>true,y=>false}, 0.0 )
			e4 = Exemple.new( {x=>true,y=>false}, 0.0 )
			e5 = Exemple.new( {x=>false,y=>false}, 1.0 )
			e = [e1,e2,e3,e4,e5]
			assert_in_delta(5.0, Exemple.chi_deux( e, x ), 0.001)
			assert_in_delta(5.0, Exemple.chi_deux( e, y ), 0.001)
			assert_equal("y", Exemple.select_attr( e, [x,y] ).label)
			
			e10 = Exemple.new( {x=>true,y=>false}, true )
			e11 = Exemple.new( {x=>false,y=>true}, false )
			e12 = Exemple.new( {x=>true,y=>false}, true )
			e13 = Exemple.new( {x=>true,y=>false}, false )
			e14 = Exemple.new( {x=>false,y=>false}, false )
			e = [e10,e11,e12,e13,e14]
			assert_in_delta(20.0/9.0, Exemple.chi_deux( e, x ), 0.001)
			assert_in_delta(1.0/1.2, Exemple.chi_deux( e, y ), 0.001)
			assert_equal("x", Exemple.select_attr( e, [x,y] ).label)
			assert_equal(2.0/3, Exemple.aggregate( [e10,e12,e13], x )[{x=>true}])
			assert_equal(0.0, Exemple.aggregate( [e11,e14], y )[{y=>true}])
			assert_equal(0.0, Exemple.aggregate( [e11,e14], x )[{x=>true}])
			assert_equal(0.4, Exemple.aggregate( e, x )[{x=>true}])
			assert_equal(0.4, Exemple.aggregate( e, y )[{y=>true}])
			
			assert_equal(0.0, Exemple.chi_deux( [], x ))
			assert_equal(0.0, Exemple.chi_deux( [e10], x ))
		end
		
		def test_perf
			v = Variable.new("v", [true,false])
			w = Variable.new("w", [true,false])
			x = Variable.new("x", [true,false])
			y = Variable.new("y", [true,false])
			z = Variable.new("z", [true,false])
			e = []
			1000.times do
				vi = rand(2) == 0
				wi = rand(2) == 0
				xi = rand(2) == 0
				yi = rand(2) == 0
				zi = rand(2) == 0
				sig = rand(1..5)
				e << Exemple.new({v=>vi,w=>wi,x=>xi,y=>yi,z=>zi},sig)
			end
			i = 0
			100.times do
				i += 1 if Exemple.select_attr( e, [v,w,x,y,z] ).label == "x"
			end
			p i
		end
	end
end
