# encoding: utf-8

require 'test/unit'

require_relative "../../learning/updatetrees"
require_relative "../../data/variable"
require_relative "../../data/potential"
require_relative "../../data/tree"

module SDYNA
	class UpdateTreeSTest < Test::Unit::TestCase		
		def test_all
			x = Variable.new("x",[true,false])
			y = Variable.new("y",[true,false])
			z = Variable.new("z",[0,1])
			diffEpsilon = 3
			
			tree = TransitionTree.new
			
			# Empty Tree
			e = Example.new({x=>true, y=>false}, 0)
			assert tree.empty?, "Bug in TransitionTree or superclass initialization."
			assert_nothing_raised do
				Learning.update_tree_s(tree, e, z, diffEpsilon)
			end
			
			assert ! tree.empty?, "tree must don't be empty after update."
			assert tree.leaf?, "tree must be a leaf after update."
			assert_equal 1, tree.examples.size
			assert_kind_of Potential, tree.content
			assert_equal 1.0, tree.content[z][0]
			assert_equal 0.0, tree.content[z][1]
			
			# Potential Update
			e = Example.new({x=>true, y=>true}, 1)
			
			assert_nothing_raised do
				Learning.update_tree_s(tree, e, z, diffEpsilon)
			end
			
			assert ! tree.empty?, "tree must don't be empty after update."
			assert tree.leaf?, "tree must be a leaf after update."
			assert_equal 2, tree.examples.size
			assert_kind_of Potential, tree.content
			assert_equal 0.5, tree.content[z][0]
			assert_equal 0.5, tree.content[z][1]
			
			# Separate leaf
			e = Example.new({x=>false, y=>false}, 0)
			
			assert_nothing_raised do
				Learning.update_tree_s(tree, e, z, diffEpsilon)
			end
			
			assert ! tree.empty?, "tree must don't be empty after update."
			assert ! tree.leaf?, "tree mustn't be a leaf after update."
			assert_equal y, tree.test
			assert_equal 3, tree.examples.size
			assert tree[true].leaf? && tree[false].leaf?
			assert_kind_of Potential, tree[true].content
			assert_kind_of Potential, tree[false].content
			assert_equal 1.0, tree[false].content[z][0]
			assert_equal 0.0, tree[false].content[z][1]
			assert_equal 2, tree[false].examples.size
			assert_equal 1.0, tree[true].content[z][1]
			assert_equal 1, tree[true].examples.size
			
			# Simple Tree and Potential Update
			e = Example.new({x=>false, y=>true}, 1)
			
			assert_nothing_raised do
				Learning.update_tree_s(tree, e, z, diffEpsilon)
			end
			
			assert ! tree.empty?, "tree must don't be empty after update."
			assert ! tree.leaf?, "tree mustn't be a leaf after update."
			assert_equal y, tree.test
			assert_equal 4, tree.examples.size
			assert tree[true].leaf? && tree[false].leaf?
			assert_kind_of Potential, tree[true].content
			assert_kind_of Potential, tree[false].content
			assert_equal 1.0, tree[false].content[z][0]
			assert_equal 0.0, tree[false].content[z][1]
			assert_equal 2, tree[false].examples.size
			assert_equal 0.0, tree[true].content[z][0]
			assert_equal 1.0, tree[true].content[z][1]
			assert_equal 2, tree[true].examples.size
		end
		
		def test_change_var
			x = Variable.new("x",[true,false])
			y = Variable.new("y",[true,false])
			z = Variable.new("z",[0,1])
			diffEpsilon = 3
			
			tree = TransitionTree.from_hash(
				y => {true => Potential.from_hash(z=>{0=>1.0,1=>0.0}),
					  false=> Potential.from_hash(z=>{0=>0.0,1=>1.0})}
			)
			e1 = Example.new({x=>false, y=>true}, 1)
			e2 = Example.new({x=>false, y=>true}, 1)
			e3 = Example.new({x=>true, y=>false}, 0)
			tree.examples << e1 << e2 << e3
			tree[false].examples << e1 << e2
			tree[true].examples << e3
			
			e = Example.new({x=>false, y=>false}, 1)
			assert_nothing_raised do
				Learning.update_tree_s(tree, e, z, diffEpsilon)
			end
			
			assert ! tree.empty?, "tree must don't be empty after update."
			assert ! tree.leaf?, "tree mustn't be a leaf after update."
			assert_equal x, tree.test
			assert_equal 4, tree.examples.size
			assert tree[true].leaf? && tree[false].leaf?
			assert_kind_of Potential, tree[true].content
			assert_kind_of Potential, tree[false].content
			assert_equal 0.0, tree[false].content[z][0]
			assert_equal 1.0, tree[false].content[z][1]
			assert_equal 3, tree[false].examples.size
			assert_equal 1.0, tree[true].content[z][0]
			assert_equal 0.0, tree[true].content[z][1]
			assert_equal 1, tree[true].examples.size
		end
	end
end # module SDYNA

