# encoding: utf-8

require 'test/unit'

require_relative "../../learning/buildtreef"
require_relative "../../data/variable"
require_relative "../../data/tree"

module SDYNA
	class BuildTreeFTest < Test::Unit::TestCase
		def test_empty
			x = Variable.new("x",[true,false])
			y = Variable.new("y",[true,false])
			z = Variable.new("z",[0,1])
			
			tree = TestNode.new
			
			assert_nothing_raised do
				Learning.reorganise_tree(tree)
			end
			
			assert tree.empty?
		end
		
		def test1
			x = Variable.new("x",[true,false])
			y = Variable.new("y",[true,false])
			z = Variable.new("z",[0,1])
			
			tree = TestNode.from_hash({
				y => {true => {x => {true => 4,
									 false=> 0}},
					  false=> {x => {true => 4,
									 false=> 1}}}
			})
			
			#~ assert_nothing_raised do
				Learning.reorganise_tree(tree)
			#~ end
			
			# The attented result
			result = TestNode.from_hash({
				x => {true => 4,
					  false => {y => {true => 0,
									  false => 1}}}
			})
			
			assert ! tree.empty?
			assert_equal x, tree.test, tree
			assert_equal result, tree
		end
	end
end # module SDYNA
