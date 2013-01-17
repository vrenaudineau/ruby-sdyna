# encoding: utf-8

require 'test/unit'

require_relative "../../data/tree"
require_relative "../../data/fmdp"
require_relative "../../planning"

module SDYNA
	class IncSVITest < Test::Unit::TestCase
		def test_empty
			x = Variable.new("x", [true,false])
			y = Variable.new("y", [true,false])
			fmdp = FMDP.new([x, y], [:a, :b])
			
			assert_nothing_raised do
				Planning.incSVI(fmdp)
			end

			assert_kind_of TransitionTree, fmdp.transitions[:a][x]
			assert fmdp.transitions[:a][x].leaf?
			assert_kind_of RewardTree, fmdp.rewards
			assert fmdp.rewards.leaf?
			assert_equal 0, fmdp.rewards.content
			assert_kind_of ValueTree, fmdp.value
			assert fmdp.value.leaf?
			assert_equal 0, fmdp.value.content
		end
		
		def test1
			# Deux variables binaires :
			# - has robot coffee
			# - has owner coffee
			hrc = Variable.new("hrc", [true,false])
			hoc = Variable.new("hoc", [true,false])
			# Avec deux actions :
			# - give, donner le café
			# - wait, attendre
			fmdp = FMDP.new([hrc, hoc], [:give, :wait])
			# Si on tente de donner, dans tous les cas, on a pas/plus après.
			fmdp.transitions[:give][hrc] = TransitionTree.from_hash(
				Potential.from_hash(hrc=>{true=>0.0,false=>1.0})
			)
			# Quand on attend, on garde son café, et on peut en obtenir un.
			fmdp.transitions[:wait][hrc] = TransitionTree.from_hash(
				hrc => {true => Potential.from_hash(hrc=>{true=>1.0,false=>0.0}),
						false=> Potential.from_hash(hrc=>{true=>0.2,false=>0.8})}
			)
			# On prend l'état du robot (si on en a un mais pas le robot, on le perd)
			fmdp.transitions[:give][hoc] = TransitionTree.from_hash(
				hrc => {true => Potential.from_hash(hoc=>{true=>1.0,false=>0.0}),
						false=> Potential.from_hash(hoc=>{true=>0.0,false=>1.0})}
			)
			# Quand on attend, rien ne change.
			fmdp.transitions[:wait][hoc] = TransitionTree.from_hash(
				hoc => {true => Potential.from_hash(hoc=>{true=>1.0,false=>0.0}),
						false=> Potential.from_hash(hoc=>{true=>0.0,false=>1.0})}
			)
			# Gagne que si has owner coffee == true
			fmdp.rewards = RewardTree.from_hash(
				hoc => {true => 10,
						false=> 0}
			)
			# Same as rewards
			fmdp.value = ValueTree.from_hash(
				hoc => {true => 10,
						false=> 0}
			)
			
			assert_nothing_raised do
				Planning.incSVI(fmdp)
			end
			
			# Transitions Trees must not have changed
			assert_kind_of TransitionTree, fmdp.transitions[:give][hoc]
			assert_equal hrc, fmdp.transitions[:give][hoc].test
			assert_kind_of TransitionTree, fmdp.transitions[:give][hrc]
			assert fmdp.transitions[:give][hrc].leaf?
			assert_kind_of TransitionTree, fmdp.transitions[:wait][hoc]
			assert_equal hoc, fmdp.transitions[:wait][hoc].test
			assert_kind_of TransitionTree, fmdp.transitions[:wait][hrc]
			assert_equal hrc, fmdp.transitions[:wait][hrc].test
			
			# Rewards Tree must not have changed
			assert_kind_of RewardTree, fmdp.rewards
			assert_equal hoc, fmdp.rewards.test
			assert_equal 10, fmdp.rewards[true].content
			assert_equal 0, fmdp.rewards[false].content
			
			# Hoped q[:wait] result
			qwaitResult = ValueTree.from_hash(
				hoc => {true =>19,
						false=>0}
			)
			assert_kind_of ValueTree, fmdp.q[:wait]
			assert_equal qwaitResult, fmdp.q[:wait]
			
			# Hoped q[:give] result
			qgiveResult = ValueTree.from_hash(
				hoc => {true =>{hrc => {true =>19,
										false=>10}},
						false=>{hrc => {true =>9,
										false=>0}}}
			)
			assert_kind_of ValueTree, fmdp.q[:give]
			assert_equal qgiveResult, fmdp.q[:give]
			
			# Hoped value result
			valueResult = ValueTree.from_hash(
				hoc => {true =>19,
						false=>{hrc => {true =>9,
										false=>0}}}
			)
			assert_kind_of ValueTree, fmdp.value
			assert_equal valueResult, fmdp.value
		end
	end
end # module SDYNA
