# encoding: utf-8

require 'test/unit'

require_relative "../../data/variable"

module SDYNA
	class VariableTest < Test::Unit::TestCase
		# Vérifie fonctionne correctement
		def test_variable
			# test initialize
			assert_nothing_raised do
				@v = SDYNA::Variable.new( "hoc", [true, false] )
			end
			assert_nothing_raised do
				SDYNA::Variable.new( "weather", ["sunny","cloudy","rainy"] )
			end
			assert_nothing_raised do
				SDYNA::Variable.new( 2, [1...2,2...3,3...4] )
			end
			assert_nothing_raised do
				SDYNA::Variable.new( {:bob=>7}, 0..9 )
			end
			assert_raise ArgumentError do
				SDYNA::Variable.new( "bob", "alice" )
			end
			# test label
			assert @v.label == 'hoc'
			# test size
			assert @v.size == 2
			# test values
			assert @v.values.kind_of?( Array ) 
			assert @v.values == [true,false]
			# test enumerable
			assert @v.to_a.join(",") == 'true,false'
		end
	end
end
