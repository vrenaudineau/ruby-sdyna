# encoding: utf-8

require 'test/unit'
require_relative "../src/node"
require_relative "../src/fmdp"

module SDYNA
	class NodeTest < Test::Unit::TestCase
		def test_simplify_and_equal
			y = Variable.new("y", [true,false])
			z = Variable.new("z", [0,1])
			
			result = normalResult = nil
			assert_nothing_raised do
				normalResult = Tree.from_hash({
					y => {true => 3,
						  false => 5}})
						  
				t = Tree.from_hash({
					z => {0 => {y => {true => {z => {0 => 3,
													 1 => 8}},
									  false => 5}},
						  1 => {y => {true => 3,
									  false => 5}}}})
				result = t.simplify!
			end
			
			assert result == normalResult
		end
		def test_append_numeric
			x = Variable.new("x", [0,1,2])
			y = Variable.new("y", [true,false])
			z = Variable.new("z", [0,1])
			
			result = normalResult = nil
			assert_nothing_raised do
				t1 = Tree.from_hash({
					z => {0 => {y => {true => {z => {0 => 3,
													 1 => 8}},
									  false => 5}},
						  1 => {y => {true => 3,
									  false => 5}}}})
				
				t2 = Tree.from_hash({
					x => {0 => {z => {0 => {y => {true => 0,
												  false => 10}},
									  1 => 5}},
						 1 => {z => {0 => 19,
									 1 => 0}},
						 2 => {z => {0 => 0,
									 1 => 15}}}})
				
				normalResult = Tree.from_hash({
					x => {0 => {z => {0 => {y => {true => 3,
												  false => 15}},
									  1 => {y => {true => 8,
												  false => 10}}}},
						  1 => {z => {0 => {y => {true => 22,
												  false => 24}},
									  1 => {y => {true => 3,
												  false => 5}}}},
						  2 => {z => {0 => {y => {true => 3,
												  false => 5}},
									  1 => {y => {true => 18,
												  false => 20}}}}}})
				
				result = t2.append!(t1, FMDP::RecompensesAddComb)
			end
			assert result == normalResult, "result=\n#{result}\nnormalResult=\n#{normalResult}"
		end
		def test_append_potential
			w = Variable.new("w", [false,true])
			x = Variable.new("x", [true,false])
			y = Variable.new("y", [true,false])
			
			result = normalResult = t1 = nil
			assert_nothing_raised do
				t1 = Tree.from_hash({
					w => {false => {y => {true  => {:pot => {w=>{true=>0.9,false=>0.1}}},
										  false => {:pot => {w=>{true=>0.0,false=>1.0}}}}},
						  true  => {:pot => {w=>{true=>1.0,false=>0.0}}}}})
				
				t2 = Tree.from_hash({
					y => {false => {x => {true => {:pot => {y=>{true=>0.9,false=>0.1}}},
										  false => {:pot => {y=>{true=>0.0,false=>1.0}}}}},
						  true  => {:pot => {y=>{true=>1.0,false=>0.0}}}}})
				
				normalResult = Tree.from_hash({
					w => {false => {y => {true  => {:pot => {w=>{true=>0.9,false=>0.1},y=>{true=>1.0,false=>0.0}}},
										  false => {x => {true  => {:pot => {w => {true=>0.0,false=>1.0},y=>{true=>0.9,false=>0.1}}},
														  false => {:pot => {w => {true=>0.0,false=>1.0},y=>{true=>0.0,false=>1.0}}}}}}},
						  true  => {y => {true  => {:pot => {w=>{true=>1.0,false=>0.0},y=>{true=>1.0,false=>0.0}}},
										  false => {x => {true  => {:pot => {w=>{true=>1.0,false=>0.0},y=>{true=>0.9,false=>0.1}}},
														  false => {:pot => {w=>{true=>1.0,false=>0.0},y=>{true=>0.0,false=>1.0}}}}}}}}
					})
					
				result = t1.append!(t2, FMDP::TransitionsMultComb)
			end
			assert result == normalResult, "result=\n#{result}\nnormalResult=\n#{normalResult}"
		end
		def test_merge
			x = Variable.new("x", [0,1,2])
			y = Variable.new("y", [true,false])
			z = Variable.new("z", [0,1])
			
			result = normalResult = nil
			assert_nothing_raised do
				t1 = Tree.from_hash({
					z => {0 => {y => {true  => 3,
									  false => 5}},
						  1 => {y => {true  => 3,
									  false => 5}}}})
				
				t2 = Tree.from_hash({
					x => {0 => {z => {0 => {y => {true  => 0,
												  false => 10}},
									  1 => 5}},
						  1 => {z => {0 => 19,
									  1 => 0}},
						  2 => {z => {0 => 0,
									  1 => 15}}}})
				
				t3 = Tree.from_hash({
					y => {true  => {x => {0 => 7,
										  1 => 3,
										  2 => 2}},
						  false => 10}})
				
				normalResult = Tree.from_hash({
					y => {true  => {x => {0 => 7,
										  1 => {z => {0 => 19,
													  1 => 3}},
										  2 => {z => {0 => 3,
													  1 => 15}}}},
						  false => {x => {0 => 10,
										  1 => {z => {0 => 19,
													  1 => 10}},
										  2 => {z => {0 => 10,
													  1 => 15}}}}}})
				
				result = Tree.merge( [t1, t2, t3], FMDP::ValeurMaxComb )
			end
			
			assert result == normalResult, "result=\n#{result}\nnormalResult=\n#{normalResult}"
		end
		def test_tree_iterator
			x = Variable.new("x", [0,1,2])
			y = Variable.new("y", [:true,:false])
			z = Variable.new("z", [0,1])
			
			t = i = result = normalResult = nil
			assert_nothing_raised do
				t = Tree.from_hash({
					x => {0 => {z => {0 => {y => {:true  => 0,
												  :false => 10}},
									  1 => 5}},
						  1 => {z => {0 => 19,
									  1 => 0}},
						  2 => {z => {0 => 0,
									  1 => 15}}}})
									  
				normalResult = [
					{x=>0,z=>0,y=>:true},
					{x=>0,z=>0,y=>:false},
					{x=>0,z=>1},
					{x=>1,z=>0},
					{x=>1,z=>1},
					{x=>2,z=>0},
					{x=>2,z=>1}
				]
				
				i = t.iterator
			end
			assert i.kind_of?(Node::PathIterator)
			assert_equal(true, i.next?)
			assert_equal({x=>0,z=>0,y=>:true}, i.next)
			
			assert_nothing_raised do
				result = t.iterator.collect do |p|	p end
			end
			assert result == normalResult, "result=\n#{result.join("\n")}\nnormal result=\n#{normalResult.join("\n")}"
		end
		
		def test_node_clone
			x = Variable.new("x", [0,1,2])
			y = Variable.new("y", [true,false])
			z = Variable.new("z", [0,1])
			
			t = Node.from_hash({
				y => {true  => {x => {0 => 7,
									  1 => {z => {0 => 19,
												  1 => 3}},
									  2 => {z => {0 => 3,
												  1 => 15}}}},
					  false => {x => {0 => 10,
									  1 => {z => {0 => 19,
												  1 => 10}},
									  2 => {z => {0 => 10,
												  1 => 15}}}}}})
		
			tclone = nil
			assert_nothing_raised do
				tclone = t.clone
			end
			assert tclone == t
			assert tclone.object_id != t.object_id
			assert tclone.parent == nil
			assert tclone.test == t.test && tclone.content == t.content
			assert tclone.branches.to_set == t.branches.to_set
			assert tclone[true] == t[true]
			assert tclone[true].object_id != t[true].object_id
			assert tclone[true].test == t[true].test && tclone[true].content == t[true].content
			assert tclone[true].branches.to_set == t[true].branches.to_set
			assert tclone[true].parent.object_id == tclone.object_id
			assert tclone[true][1][1] == t[true][1][1]
			assert tclone[true][1][1].parent.parent.parent == tclone
		end
		
		def test_replace1
			x = Variable.new("x", [0,1,2])
			y = Variable.new("y", [true,false])
			z = Variable.new("z", [0,1])
			
			t1 = Node.from_hash({
				y => {true  => {x => {0 => 7,
									  1 => {z => {0 => 19,
												  1 => 3}},
									  2 => {z => {0 => 3,
												  1 => 15}}}},
					  false => {x => {0 => 10,
									  1 => {z => {0 => 19,
												  1 => 10}},
									  2 => {z => {0 => 10,
												  1 => 15}}}}}})
			
			t2 = Node.from_hash({
				x => {0 => {z => {0 => {y => {true  => 0,
											  false => 10}},
								  1 => 5}},
					  1 => {z => {0 => 19,
								  1 => 0}},
					  2 => {z => {0 => 0,
								  1 => 15}}}})
			
			# Sauvegarde pour garder une trace des objets effacés.
			t1back = {nil => t1}
			t1back[true] = {nil=>t1[true]}
			t1back[false] = {nil=>t1[false]}
			t1back[true][0] = {nil=>t1[true][0]}
			t1back[true][1] = {nil=>t1[true][1]}
			t1back[true][2] = {nil=>t1[true][2]}
			t1back[true][1][0] = {nil=>t1[true][1][0]}
			t1back[true][1][1] = {nil=>t1[true][1][1]}
			t1back[true][2][0] = {nil=>t1[true][2][0]}
			t1back[true][2][1] = {nil=>t1[true][2][1]}
			
			t2back = {nil=>t2}
			t2back[0] = t2[0]
			
			#
			assert_nothing_raised do
				t1[true].replace!(t2)
			end
			
			# Ce qui doit rester pareil, reste pareil.
			assert t1.object_id == t1back[nil].object_id && t1.test == y
			assert t1[true].object_id == t1back[true][nil].object_id && t1[true].test == x
			assert t1[true].parent.object_id == t1back[nil].object_id
			assert t1[false].object_id == t1back[false][nil].object_id && t1[false].test == x
			assert t1[false] == t1back[false][nil] && t1[false].test == x
			assert t1[false].parent.object_id == t1back[nil].object_id
			
			# Ce qui doit changer, change.
			assert t1[true][0].object_id == t2[0].object_id
			assert t1[true][0].parent.object_id != t2.object_id
			assert t1[true][0].parent.object_id == t1[true].object_id
			assert t1back[true][0].object_id != t1[true][0].object_id
			assert t1back[true][0][nil].parent.nil?
			assert t1back[true][1][nil].parent.nil?
			assert t2back[nil].parent.nil?
			assert t2back[0].parent.object_id != t2back[nil].object_id
			assert t2back[0].parent.object_id == t1[true].object_id
		end
	end
end
