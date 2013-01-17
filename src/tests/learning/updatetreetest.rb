# encoding: utf-8

require 'test/unit'

require_relative "../../learning/updatetree"
require_relative "../../data/variable"
require_relative "../../data/tree"

module SDYNA
	class UpdateTreeTest < Test::Unit::TestCase
		def test_empty
			x = Variable.new("x",[true,false])
			y = Variable.new("y",[true,false])
			z = Variable.new("z",[0,1])
			
			tree = RewardTree.new
			
			e = Example.new({x=>true, y=>false}, 5)
			
			assert tree.empty?, "Bug in RewardTree or superclass initialization."
			assert_nothing_raised do
				Learning.update_tree(tree, e)
			end
			
			assert ! tree.empty?, "tree must don't be empty after update."
			assert tree.leaf?, "tree must be a leaf after update."
			assert_equal 5, tree.content
			assert_equal 1, tree.examples.size
		end
		
		def test_simple_update
			x = Variable.new("x",[true,false])
			y = Variable.new("y",[true,false])
			z = Variable.new("z",[0,1])
			
			tree = RewardTree.from_hash({
				x => {true => 4,
					  false => {y => {true => 0,
									  false => 1}}}
			})
			e1 = Example.new({x=>true, y=>true}, 4)
			e2 = Example.new({x=>false, y=>true}, 0)
			e3 = Example.new({x=>false, y=>false}, 1)
			tree.examples << e1 << e2 << e3
			tree[true].examples << e1
			tree[false].examples << e2 << e3
			tree[false][true].examples << e2
			tree[false][false].examples << e3
			
			assert_equal 3, tree.examples.size, "Error in Tree construction."
			assert_equal 1, tree[true].examples.size, "Error in Tree construction."
			assert_equal 2, tree[false].examples.size, "Error in Tree construction."
			
			e = Example.new({x=>true, y=>false}, 4)
			assert_nothing_raised do
				Learning.update_tree(tree, e)
			end
			
			# The attented result
			result = RewardTree.from_hash({
				x => {true => 4,
					  false => {y => {true => 0,
									  false => 1}}}
			})
			
			assert ! tree.leaf?
			assert_equal x, tree.test
			assert_equal result, tree
			assert_equal 4, tree.examples.size
			assert_equal 2, tree[true].examples.size
			assert_equal 2, tree[false].examples.size
		end
		
		def test_separate_leaf
			x = Variable.new("x",[true,false])
			y = Variable.new("y",[true,false])
			z = Variable.new("z",[0,1])
			
			tree = RewardTree.from_hash({
				x => {true => 4,
					  false => {y => {true => 0,
									  false => 1}}}
			})
			e1 = Example.new({x=>true, y=>true}, 4)
			e2 = Example.new({x=>false, y=>true}, 0)
			e3 = Example.new({x=>false, y=>false}, 1)
			tree.examples << e1 << e2 << e3
			tree[true].examples << e1
			tree[false].examples << e2 << e3
			tree[false][true].examples << e2
			tree[false][false].examples << e3
			
			assert_equal 3, tree.examples.size, "Error in Tree construction."
			assert_equal 1, tree[true].examples.size, "Error in Tree construction."
			assert_equal 2, tree[false].examples.size, "Error in Tree construction."
			
			e = Example.new({x=>true, y=>false}, 2)
			assert_nothing_raised do
				Learning.update_tree(tree, e)
			end
			
			# The attented result
			result = RewardTree.from_hash({
				x => {true => {y => {true => 4,
									  false => 2}},
					  false => {y => {true => 0,
									  false => 1}}}
			})
			
			assert ! tree.leaf?
			assert_equal x, tree.test
			assert_equal result, tree
			assert_equal 4, tree.examples.size
			assert_equal 2, tree[true].examples.size
			assert_equal 2, tree[false].examples.size
			assert_equal 1, tree[true][true].examples.size
			assert_equal 1, tree[true][false].examples.size
			assert_equal 1, tree[false][true].examples.size
			assert_equal 1, tree[false][false].examples.size
		end
		
		def test_change_var
			x = Variable.new("x",[true,false])
			y = Variable.new("y",[true,false])
			z = Variable.new("z",[0,1])
			
			tree = RewardTree.from_hash({
				x => {true => 4,
					  false => {y => {true => 0,
									  false => 1}}}
			})
			e1 = Example.new({x=>true, y=>true}, 4)
			e2 = Example.new({x=>false, y=>true}, 0)
			e3 = Example.new({x=>false, y=>false}, 1)
			tree.examples << e1 << e2 << e3
			tree[true].examples << e1
			tree[false].examples << e2 << e3
			tree[false][true].examples << e2
			tree[false][false].examples << e3
			
			assert_equal 3, tree.examples.size, "Error in Tree construction."
			assert_equal 1, tree[true].examples.size, "Error in Tree construction."
			assert_equal 2, tree[false].examples.size, "Error in Tree construction."
			
			e = Example.new({x=>true, y=>false}, 1)
			assert_nothing_raised do
				Learning.update_tree(tree, e)
			end
			
			# The attented result
			result = RewardTree.from_hash({
				y => {true => {x => {true => 4,
									  false => 0}},
					  false => 1}
			})
			
			assert ! tree.leaf?
			assert_equal y, tree.test
			assert_equal result, tree
			assert_equal 4, tree.examples.size
			assert_equal 2, tree[true].examples.size
			assert_equal 2, tree[false].examples.size
			assert_equal 1, tree[true][true].examples.size
			assert_equal 1, tree[true][false].examples.size
		end
	end
end # module SDYNA
