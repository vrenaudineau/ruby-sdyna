# encoding: utf-8

require 'test/unit'

require_relative "../../learning/buildtrees"
require_relative "../../data/variable"
require_relative "../../data/tree"

module SDYNA	
	class BuildTreeSTest < Test::Unit::TestCase
		def test_empty
			x = Variable.new("x",[true,false])
			y = Variable.new("y",[true,false])
			z = Variable.new("z",[0,1])
			
			tree = TestNode.new
			
			es = Examples.new
			
			Learning.build_tree_s(tree, es, z, 0.0)
			
			assert tree.empty?
		end
		
		def test1
			x = Variable.new("x",[true,false])
			y = Variable.new("y",[true,false])
			z = Variable.new("z",[0,1])
			
			tree = TransitionTree.new
			
			es = Examples.new
			es << Example.new({x=>true,y=>false}, 1)
			es << Example.new({x=>true,y=>true}, 1)
			es << Example.new({x=>false,y=>false}, 0)
			es << Example.new({x=>false,y=>true}, 1)
			es << Example.new({x=>true,y=>true}, 1)
			es << Example.new({x=>false,y=>false}, 0)
			es << Example.new({x=>false,y=>true}, 1)
			es << Example.new({x=>true,y=>false}, 1)
			es << Example.new({x=>false,y=>false}, 0)
			es << Example.new({x=>true,y=>false}, 1)
			
			assert tree.empty?
			#~ assert_nothing_raised do
				Learning.build_tree_s(tree, es, z, 0.0)
			#~ end
			
			# The attented result
			result = TransitionTree.from_hash({
				x => {true => Potential.from_hash({z=>{0=>0.0,1=>1.0}}),
					  false => {y => {true => Potential.from_hash({z=>{0=>0.0,1=>1.0}}),
									  false => Potential.from_hash({z=>{0=>1.0,1=>0.0}})}}}
			})
			
			assert ! tree.empty?
			assert_equal x, tree.test, tree
			assert_equal result, tree
		end
	end
end # module SDYNA
