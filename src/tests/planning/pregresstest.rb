# encoding: utf-8

require 'test/unit'

require_relative "../../data/tree"
require_relative "../../data/fmdp"
require_relative "../../planning"

module SDYNA
	class PRegressTest < Test::Unit::TestCase
		def test_empty
			x = Variable.new("x", [true,false])
			y = Variable.new("y", [true,false])
			fmdp = FMDP.new([x, y], [:a])
			node = ValueTree.new(0)
			a = :a
			
			rtree = nil # Result Tree
			assert_nothing_raised do
				rtree = Planning.p_regress(fmdp, node, a)
			end
			
			assert_kind_of TransitionTree, rtree
			assert rtree.empty?
		end
		
		def test_boutillier
			x = Variable.new("x", [true,false])
			y = Variable.new("y", [true,false])
			z = Variable.new("z", [true,false])
			fmdp = FMDP.new([x, y, z], [:a])
			
			fmdp.transitions[:a][y] = TransitionTree.from_hash(
				y => {true => Potential.from_hash(y=>{true=>1.0,false=>0.0}),
					  false=> {x => {true => Potential.from_hash(y=>{true=>0.9,false=>0.1}),
									 false=> Potential.from_hash(y=>{true=>0.0,false=>1.0})}}}
			)
			fmdp.transitions[:a][z] = TransitionTree.from_hash({
				z => {true => Potential.from_hash(z=>{true=>1.0,false=>0.0}),
					  false=> {y => {true => Potential.from_hash(z=>{true=>0.9,false=>0.1}),
									 false=> Potential.from_hash(z=>{true=>0.0,false=>1.0})}}}
			})
			fmdp.rewards = RewardTree.from_hash({
				z => {true =>10,
					  false=>0}
			})
			fmdp.value = ValueTree.from_hash(
				z => {true =>10,
					  false=>0}
			)
			a = :a
			
			rtree = nil # Result Tree
			assert_nothing_raised do
				rtree = Planning.p_regress(fmdp, fmdp.value, a)
			end
			
			assert_kind_of TransitionTree, rtree
			assert ! rtree.empty?
			assert_equal z, rtree.test
			assert_kind_of Potential, rtree[true].content
			assert_equal 1.0, rtree[true].content[z][true]
			assert_equal y, rtree[false].test
			assert_equal 0.9, rtree[false][true].content[z][true]
			assert_equal 0.0, rtree[false][false].content[z][true]
			
			fmdp.value = ValueTree.from_hash(
				z => {true => 19,
					  false=> {y => {true =>8.1,
									 false=>0}}}
			)
			assert_nothing_raised do
				rtree = Planning.p_regress(fmdp, rtree, a)
			end
			rtree.simplify!
			
			assert_kind_of TransitionTree, rtree
			assert ! rtree.empty?
			assert_equal z, rtree.test, rtree
			assert_kind_of Potential, rtree[true].content
			assert_equal 1.0, rtree[true].content[z][true]
			assert_equal y, rtree[false].test, rtree.to_s
			assert_kind_of Potential, rtree[false][true].content, rtree.to_s
			assert_equal 0.9, rtree[false][true].content[z][true]
			assert_equal 1.0, rtree[false][true].content[y][true]
			assert_equal x, rtree[false][false].test, rtree.to_s
			assert_kind_of Potential, rtree[false][false][true].content, rtree.to_s
			assert_equal 0.0, rtree[false][false][true].content[z][true]
			assert_equal 0.9, rtree[false][false][true].content[y][true]
		end
	end
end # module SDYNA
