# encoding: utf-8

require 'test/unit'

require_relative "../../data/example"
require_relative "../../data/examples2"

module SDYNA
	class ExampleTest < Test::Unit::TestCase
		def test_examples
			x = Variable.new("x", [true,false])
			y = Variable.new("y", [true,false])
			
			e1 = Example.new( {x=>true,y=>false}, 0.0 )
			e2 = Example.new( {x=>false,y=>true}, 4.0 )
			e3 = Example.new( {x=>true,y=>false}, 0.0 )
			e4 = Example.new( {x=>true,y=>false}, 0.0 )
			e5 = Example.new( {x=>false,y=>false}, 1.0 )
			e = Examples.new([e1,e2,e3,e4,e5])
			assert_in_delta(5.0, e.chi_deux(x), 0.001)
			assert_in_delta(5.0, e.chi_deux(y), 0.001)
			
			e10 = Example.new( {x=>true,y=>false}, true )
			e11 = Example.new( {x=>false,y=>true}, false )
			e12 = Example.new( {x=>true,y=>false}, true )
			e13 = Example.new( {x=>true,y=>false}, false )
			e14 = Example.new( {x=>false,y=>false}, false )
			e = Examples.new([e10,e11,e12,e13,e14])
			assert_in_delta(20.0/9.0, e.chi_deux(x), 0.001)
			assert_in_delta(1.0/1.2, e.chi_deux(y), 0.001)
			assert_equal(x, e.select_attr([x,y]))
			assert_equal(2.0/3, Examples.new([e10,e12,e13]).aggregate(x)[{x=>true}])
			assert_equal(0.0, Examples.new([e11,e14]).aggregate(y)[{y=>true}])
			assert_equal(0.0, Examples.new([e11,e14]).aggregate(x)[{x=>true}])
			assert_equal(0.4, e.aggregate(x)[{x=>true}])
			assert_equal(0.4, e.aggregate(y)[{y=>true}])
			
			assert_equal(0.0, Examples.new([]).chi_deux(x))
			assert_equal(0.0, Examples.new([e10]).chi_deux(x))
		end
		
		#~ def test_perf
		def perf
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
				e << Example.new({v=>vi,w=>wi,x=>xi,y=>yi,z=>zi},sig)
			end
			i = 0
			100.times do
				i += 1 if Example.select_attr( e, [v,w,x,y,z] ).label == "x"
			end
		end
	end
end
