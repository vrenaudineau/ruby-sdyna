# encoding: utf-8

require 'test/unit'

require_relative "../../data/tree"
require_relative "../../data/fmdp"
require_relative "../../planning"

module SDYNA
	class RegressTest < Test::Unit::TestCase
		def test_empty
			x = Variable.new("x", [true,false])
			y = Variable.new("y", [true,false])
			fmdp = FMDP.new([x, y], [:a])
			a = :a
			
			rtree = nil # Result Tree
			assert_nothing_raised do
				rtree = Planning.regress(fmdp, a)
			end
			
			assert_kind_of ValueTree, rtree
			assert ! rtree.empty?
			assert rtree.leaf?
			assert_equal 0, rtree.content
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
				rtree = Planning.regress(fmdp, a)
			end
			
			assert_kind_of ValueTree, rtree
			assert ! rtree.empty?
			assert_equal z, rtree.test
			assert_in_delta 19.0, rtree[true].content, 0.01
			assert_equal y, rtree[false].test
			assert_in_delta 8.1, rtree[false][true].content, 0.01
			assert_in_delta 0.0, rtree[false][false].content, 0.01
			fmdp.value = rtree
			
			assert_nothing_raised do
				rtree = Planning.regress(fmdp, a)
			end
			
			assert_kind_of ValueTree, rtree
			assert ! rtree.empty?
			assert_equal z, rtree.test, rtree
			assert_in_delta 27.1, rtree[true].content, 0.01
			assert_equal y, rtree[false].test
			assert_in_delta 16.12, rtree[false][true].content, 0.01
			assert_equal x, rtree[false][false].test
			assert_in_delta 6.56, rtree[false][false][true].content, 0.01
			assert_in_delta 0.0, rtree[false][false][false].content, 0.01
		end
	end
end # module SDYNA
