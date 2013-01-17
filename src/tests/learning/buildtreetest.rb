# encoding: utf-8

require 'test/unit'

require_relative "../../learning/buildtree"
require_relative "../../data/variable"
require_relative "../../data/tree"

module SDYNA	
	class BuildTreeTest < Test::Unit::TestCase
		def test_empty
			n = TestNode.new
			es = Examples.new
			
			Learning.build_tree(n, es)
			
			assert n.empty?
		end
		
		def test1
			x = Variable.new("x",[true,false])
			y = Variable.new("y",[true,false])
			
			tree = TestTree.new
			
			es = Examples.new
			es << Example.new({x=>true,y=>false}, 5)
			es << Example.new({x=>true,y=>true}, 5)
			es << Example.new({x=>false,y=>false}, 0)
			es << Example.new({x=>false,y=>true}, 1)
			es << Example.new({x=>true,y=>true}, 5)
			es << Example.new({x=>false,y=>false}, 0)
			es << Example.new({x=>false,y=>true}, 1)
			es << Example.new({x=>true,y=>false}, 5)
			es << Example.new({x=>true,y=>false}, 5)
			
			assert tree.empty?
			assert_nothing_raised do
				Learning.build_tree(tree, es)
			end
			
			# The attented result
			result = TestTree.from_hash({
				x => {true => 5,
					  false => {y => {true => 1,
									  false => 0}}}
			})
			
			assert ! tree.empty?
			assert_equal x, tree.test, tree
			assert_equal result, tree
		end
	end
end # module SDYNA
