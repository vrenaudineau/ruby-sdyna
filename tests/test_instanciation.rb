# encoding: utf-8

require 'test/unit'
require_relative "../src/instanciation"

module SDYNA
	class InstanciationTest < Test::Unit::TestCase
		
		V1 = Variable.new( "hoc", [true, false] )
		V2	= Variable.new( "weather", ["sunny","cloudy","rainy"] )
		V3	= Variable.new( "hrc", [true,false] )
			
		def test_crochets_egal
			i = nil
			# test new et crochet
			assert_nothing_raised do
				i = Instanciation.new
				i[V1] = true
			end
			assert_raise ArgumentError do
				i[V2] = 1
			end
			assert_nothing_raised do
				i[V2] = "sunny"
			end
		end
		def test_add
			assert_nothing_raised do
				i = Instanciation.new.add(V1, true).add(V2, "cloudy")
			end
		end
		def test_vars
			i = Instanciation.new.add(V1, true).add(V2, "rainy")
			assert i.vars.kind_of?(Array)
			assert i.vars.size == 2
			assert i.vars == [V1,V2]
			assert( (i.vars.collect { |v| v.label }.sort) == ["hoc","weather"].sort )
			assert( (i.vars.collect { |v| v.label }.sort) == ["hoc","weather"].sort )
		end
		def test_crochets
			i = Instanciation.new.add(V1, true).add(V2, "sunny")
			assert i[V1] == true
			assert i[V2] == "sunny"
			assert i[V3] == nil
		end
		def test_next
			i = Instanciation.new.add(V1, false).add(V2, "cloudy")
			assert i.next? == true
			assert i[V1] == false && i[V2] == "cloudy"
			assert i.next == i
			assert i[V1] == false && i[V2] == "rainy"
			assert i.next? == false
			assert_nothing_raised do i.next end
			assert i[V1] == true && i[V2] == "sunny"
		end
		def test_from_hash
			i = nil
			assert_nothing_raised do
				i = Instanciation.from_hash({V1=> true, V2=>"cloudy"})
			end
			assert i.vars == [V1,V2]
			assert i[V1] == true && i[V2] == "cloudy"		
		end
	end
end
