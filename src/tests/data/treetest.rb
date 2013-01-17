# encoding: utf-8

require 'test/unit'
require "set"

require_relative "../../data/tree"

module SDYNA
	class NodeTest < Test::Unit::TestCase
		def test_from_hash
			t1 = nil
			assert_nothing_raised do
				t1 = Node.from_hash({
					151=>{1=>{157=>{0=>167,
									1=>173}},
						  2=>{163=>{0=>179,
									1=>181}}}
				})
			end
			t2 = Node.new(151)
			t2[1] = Node.new(157)
			t2[2] = Node.new(163)
			t2[1][0] = Node.new(167)
			t2[1][1] = Node.new(173)
			t2[2][0] = Node.new(179)
			t2[2][1] = Node.new(181)
			assert_equal t2, t1
		end
		def test_initialize
			# test without parameters
			n1 = nil
			assert_nothing_raised do
				n1 = Node.new
			end
			assert_nil n1.content
			assert_nil n1.parent
			assert n1.instance_variables.include?(:@branches)
			assert n1.instance_variable_get(:@branches).empty?
			
			# test with one parameters
			n2 = nil
			assert_nothing_raised do
				n2 = Node.new(2)
			end
			assert_equal 2, n2.content
			assert_nil n2.parent
			assert n2.instance_variable_get(:@branches).empty?
			
			# test with all parameters
			n3 = nil
			assert_nothing_raised do
				n3 = Node.new(3, n1)
			end
			assert_equal 3, n3.content
			assert_same n1, n3.parent
			assert n3.instance_variable_get(:@branches).empty?
		end
		def test_assign#[]=
			n1 = Node.new(5)
			n2 = Node.new(7)
			n3 = Node.new(11)
			n4 = Node.new(13)
			
			# test regular assignment 
			assert_nothing_raised do
				n1[true] = n2
				n1[false] = n3
			end
			assert_same n1, n2.parent
			assert_same n1, n3.parent
			
			# Get @branches to test it directly
			assert n1.instance_variables.include?(:@branches)
			branches = n1.instance_variable_get(:@branches)
			
			assert ! branches.empty?
			assert_not_nil branches[true]
			assert_not_nil branches[false]
			assert_same n2, branches[true]
			assert_same n3, branches[false]
			
			# test replacement assignment
			assert_nil n4.parent
			assert_nothing_raised do
				n1[true] = n4
			end
			assert_same n1, n4.parent
			assert_nil n2.parent
			assert_same n4, branches[true]
			
			# test deplacement
			assert_nothing_raised do
				n1[nil] = n3
			end
			assert_same n3, branches[nil]
			assert_nil branches[false]
		end
		def test_get#[]
			n1 = Node.new(17)
			n2 = Node.new(19)
			n3 = Node.new(23)
			n4 = Node.new(0)
			n1[1] = n2
			n1[3] = n3
			
			assert_same n2, n1[1]
			assert_same n3, n1[3]
			assert_raise ArgumentError do
				n1[2]
			end
			assert_equal 3, n1[n3]
			assert_raise ArgumentError do
				n1[n4]
			end
			assert_raise ArgumentError do
				n1["hello"]
			end
		end
		def test_equal#==
			n1 = Node.new(29)
			n2 = Node.new(31)
			n3 = Node.new(37)
			n4 = Node.new(29)
			n5 = Node.new(31)
			n6 = Node.new(37)
			
			# test type
			assert n1 != "coucou"
			assert n1 != 29
			assert Node.new == Node.new
			
			# test content
			assert Node.new(41) == Node.new(41)
			assert Node.new(41) != Node.new
			assert Node.new(41) != Node.new(43)
			assert n1 == n4
			
			# TEST SUBTREES
			
			# Doesn't test parents.
			# n1(29) -"1"> n2(31)
			# n4(29) -"1"> n5(31)
			n1["1"] = n2
			n4["1"] = n5
			assert n2 == n5
			assert n1 == n4
			
			# Number of branch is different
			# n1(29) -"1"> n2(31)
			#        -"2"> n3(37)
			# n4(29) -"1"> n5(31)
			n1["2"] = n3
			assert n1 != n4
			
			# Number of branch is equal, but labels are differents
			# n1(29) -"1"> n2(31)
			#        -"2"> n3(37)
			# n4(29) -"1"> n5(31)
			#        -"3"> n6(37)
			n4["3"] = n6
			assert n1 != n4
			
			# Number of branch is equal, and labels are equals
			# n1(29) -"1"> n2(31)
			#        -"2"> n3(37)
			# n4(29) -"1"> n5(31)
			#        -"2"> n6(37)
			n4["2"] = n6
			assert n1 == n4
		end
		def test_branches
			n1 = Node.new(47)
			n2 = Node.new(53)
			n3 = Node.new(59)
			n4 = Node.new(61)
			
			assert_kind_of Array, n1.branches
			assert n1.branches.empty?
			
			n1[1] = n2
			n1[2] = n3
			assert_equal [1,2], n1.branches
			
			n1[1] = n4
			assert_equal [1,2], n1.branches
			
			n1[3] = n3
			assert_equal [1,3], n1.branches
		end
		def test_children
			n1 = Node.new(67)
			n2 = Node.new(71)
			n3 = Node.new(73)
			
			assert_kind_of Array, n1.children
			assert n1.children.empty?
			
			n1[1] = n2
			n1[2] = n3
			assert_equal [n2,n3], n1.children
			
			n1[3] = n3
			assert_equal [n2,n3], n1.children
		end
		def test_clone
			n1 = Node.new(313)
			n2 = Node.new(317)
			n3 = Node.new(331)
			n4 = Node.new(337)
			# n1 -1> n2 -1> n3
			#           -2> n4
			n1[1] = n2
			n2[1] = n3
			n2[2] = n4
			
			n = nil
			assert_nothing_raised do
				n = n1.clone
			end
			# Assert ==
			assert n == n1, "Possible error in ==."
			# Assert all is cloned, no n1 element in n.
			assert_not_same n1, n
			assert_nil n.parent
			assert_not_same n2, n[1]
			assert_same n, n[1].parent
			assert_not_same n3, n[1][1]
			assert_same n[1], n[1][1].parent
			# Assert no change in initial n1
			assert_nil n1.parent
			assert_equal 1, n1.children.size
			assert_equal [1], n1.branches
			assert_same n2, n1[1]
			assert_same n1, n2.parent
			assert_equal 337, n1[1][2].content
			assert_same n1, n1[1][2].parent.parent
			assert_nil n1[1][2].parent.parent.parent
		end
		def test_detach_children#!
			n1 = Node.new(79)
			n2 = Node.new(83)
			n3 = Node.new(89)
			
			n1[[1]] = n2
			n1[[1,1]] = n3
			
			assert_equal 2, n1.children.size
			assert_same n1, n2.parent
			assert_same n1, n3.parent
			
			n1.detach_children!
			assert_equal 0, n1.children.size
			assert_nil n2.parent
			assert_nil n3.parent
		end
		def test_each
			n1 = Node.new(97)
			n2 = Node.new(101)
			n3 = Node.new(103)
			
			r = []
			n1.each do |branch,child|
				r << [branch,child]
			end
			assert_equal [], r
			
			n1[:vrai] = n2
			n1[:faux] = n3
			
			r = Set.new
			n1.each do |branch,child|
				r << [branch,child]
			end
			assert_equal [[:vrai,n2],[:faux,n3]].to_set, r
		end
		def test_hash_eql
		end
		def test_init_copy
			n = Node.new(0)
			n0 = Node.new("0")
			n[0] = n0
			
			n1 = Node.new(347)
			n2 = Node.new(349)
			n3 = Node.new(353)
			n4 = Node.new(359)
			# n1 -1> n2 -1> n3
			#           -2> n4
			n1[1] = n2
			n2[1] = n3
			n2[2] = n4
			assert_nothing_raised do
				n.init_copy(n1)
			end
			# Assert ==
			assert_equal n1, n, "Possible error in ==."
			# Assert all is cloned, no n1 element in n.
			assert_not_same n1, n
			assert_nil n.parent
			assert_not_same n2, n[1]
			assert_same n, n[1].parent
			assert_not_same n3, n[1][1]
			assert_same n[1], n[1][1].parent
			# Assert no change in initial n1
			assert_nil n1.parent
			assert_equal 1, n1.children.size
			assert_equal [1], n1.branches
			assert_same n2, n1[1]
			assert_same n1, n2.parent
			assert_equal 359, n1[1][2].content
			assert_same n1, n1[1][2].parent.parent
			assert_nil n1[1][2].parent.parent.parent
			# Assert previous subtree id correctly removed
			assert_equal 1, n.branches.size
			assert_raise ArgumentError do
				n[0]
			end
			assert_nil n0.parent
		end
		def test_assign_leaf
		end
		def test_is_leaf
		end
		def test_leafs
			n1 = Node.new(107)
			n2 = Node.new(109)
			n3 = Node.new(113)
			n4 = Node.new(127)
			n1[:oui] = n2
			n1[:non] = n3
			n2[:maybe] = n4
			assert_equal [n3,n4].to_set, n1.leafs.to_set
		end
		def test_replace
			n1 = Node.new(131)
			n2 = Node.new(137)
			n3 = Node.new(139)
			n4 = Node.new(149)
			# n1 -1> n2 -1> n3
			#           -2> n4
			n1[1] = n2
			n2[1] = n3
			n2[2] = n4
			
			n1.replace!(n2)
			assert_equal 137, n1.content
			assert_same n1, n3.parent
			assert_same n1, n4.parent
			assert_equal( {1=>n3,2=>n4}, n1.instance_variable_get(:@branches) )
			assert_nil n2.parent
		end
		def test_is_root
		end
		def test_set_root
		end
		def test_size
			n1 = Node.new(401)
			n2 = Node.new(409)
			n3 = Node.new(419)
			n4 = Node.new(421)
			# n1 -1> n2 -1> n3
			#           -2> n4
			n1[1] = n2
			n2[1] = n3
			n2[2] = n4
			assert_equal 4, n1.size
		end
	end # class NodeTest

	class TestNodeTest < Test::Unit::TestCase
		def test_from_hash
			# 
			x = [true,false]
			t = nil
			assert_nothing_raised do
				t = TestNode.from_hash({
					x=>{true =>0,
						false=>1}
				})
			end
			assert_equal x, t.content
			assert_equal 2, t.children.size
			assert_equal 0, t[true].content
			assert_instance_of TestNode, t
			assert_instance_of TestNode, t[true]
		end
		def test_get#[]
			x = [1,2]
			y = [0,1]
			t = TestNode.from_hash({
				x=>{1=>{y=>{0=>191,
							1=>193}},
					2=>{y=>{0=>197,
							1=>199}}}
			})
			assert_equal y, t[1].content
			assert_equal 191, t[1][0].content
			assert_equal 193, t[x=>1,y=>1].content
			assert_equal 199, t[y=>1,x=>2].content
		end
		def test_append
			x = [1,2]
			y = [0,1]
			t1 = TestNode.from_hash({
				x=>{1=>{y=>{0=>211,
							1=>223}},
					2=>227}
			})
			t2 = TestNode.from_hash({
				x=>{1=>229,
					2=>233}
			})
			
			r1 = TestNode.from_hash({
				x=>{1=>{y=>{0=>{x=>{1=>211+229,
									2=>211+233}},
							1=>{x=>{1=>223+229,
									2=>223+233}}}},
					2=>{x=>{1=>227+229,
							2=>227+233}}}
			})
			assert_nothing_raised do
				t1.append!(t2,false)
			end
			assert_equal r1, t1
			
			r2 = TestNode.from_hash({
				x=>{1=>{y=>{0=>211+229+229,
							1=>223+229+229}},
					2=>227+233+233}
			})
			t2.append!(t1,true)
			assert_equal r2, t2, "simplify! in append! doesn't work."
		end
		def test_merge
			x = [0,1]
			y = [2,3]
			z = [4,5]
			t1 = TestNode.from_hash({
				x=>{0=>367,
					1=>373}
			})
			t2 = TestNode.from_hash({
				y=>{2=>379,
					3=>383}
			})
			t3 = TestNode.from_hash({
				z=>{4=>{x=>{0=>389,
							1=>397}},
					5=>397}
			})
			r  = TestNode.from_hash({
				x=>{0=>{y=>{2=>{z=>{4=>367+379+389,
									5=>367+379+397}},
							3=>{z=>{4=>367+383+389,
									5=>367+383+397}}}},
					1=>{y=>{2=>373+379+397,
							3=>373+383+397}}}
			})
			assert_nothing_raised do
				t1.merge!([t2,t3])
			end
			assert_equal r, t1, "Maybe simplify doesn't work corectly ?"
		end
		def test_path
			x = [1,2]
			y = [0,1]
			z = [true, false]
			t = TestNode.from_hash({
				x=>{1=>{y=>{0=>{z=>{true =>263,
									false=>269}},
							1=>{z=>{true=>271,
									false=>277}}}},
					2=>{z=>{true=>281,
							false=>283}}}
			})
			assert_equal 263, t[1][0][true].content, "Error in node[b1][b2]."
			assert_equal({x=>1,y=>0,z=>true}, t[1][0][true].path)
			assert_equal 277, t[x=>1,y=>1,z=>false].content, "Error in node[t1=>v1,t2=>v2]"
			assert_equal({x=>1,y=>1,z=>false}, t[x=>1,y=>1,z=>false].path)
			assert_equal({x=>1,y=>1,z=>false}, t[y=>1,z=>false,x=>1].path, "Error for node[t2=>v3,t1=>v1] when tests are not in the good order")
		end
		def test_simplify
			x = [1,2]
			y = [0,1,2]
			t = TestNode.from_hash({
				x=>{1=>{y=>{0=>{x=>{1=>239,
									2=>241}},
							1=>{x=>{1=>239,
									2=>251}},
							2=>239}},
					2=>{x=>{1=>257,
							2=>239}}}
			})
			r = TestNode.from_hash({:leaf=>239})
			assert_nothing_raised do
				t.simplify!
			end
			assert_equal r, t
		end
		def test_assign_test
			x = [true,false]
			t = TestNode.new(293)
			n1= TestNode.new(307)
			n2= TestNode.new(311)
			t[0] = n1
			t[1] = n2
			
			assert_same t, n1.parent, "Error in []="
			assert_same t, n2.parent, "Error in []="
			assert_equal [0,1].to_set, t.branches.to_set, "Error in []="
			assert_nothing_raised do
				t.test = x
			end
			assert_nil n1.parent
			assert_nil n2.parent
			assert_same x, t.content
			assert_equal [true,false].to_set, t.branches.to_set
			assert_same t, t[true].parent
			assert_nil t[true].content
			assert t[false].branches.empty?
		end
	end
	
	class OldNodeTest# < Test::Unit::TestCase
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
				
				result = t2.append!(t1, FMDP::RewardsAddComb)
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
				
				result = Tree.merge( [t1, t2, t3], FMDP::ValueMaxComb )
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
