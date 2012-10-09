# encoding: utf-8

require "set"

module SDYNA
	## Une Variable à un nom (=label, un String),
	## et un ensemble de valeurs -uniques- possibles (=values).
	## values doit être un enumerable, ça peut être un Set, un Array ou un Range par exemple.
	class Variable
		include Enumerable
		## Une variable ne peut pas se modifier, ses attributs sont en lecture seule.
		attr_reader :label, :values
		#
		def initialize( label, values )
			raise ArgumentError, "values has to be an Enumerable." unless values.kind_of?(Enumerable)
			@label, @values = label.to_s, values
		end
		# Itère sur values.
		def each
			@values.each do |val|
				yield val
			end
			self
		end
		# Affiche juste le label.
		def inspect
			return "'#{@label}'"
		end
		## La taille d'une variable est la taille du domaine de ses valeurs.
		def size
			return values.size
		end	
		#
		def to_s
			return "Var['#{@label}' in #{@values.join(",")}]"
		end
		## Est ce que v fait partie des valeurs possibles de cette variable ?
		def value?( v )
			return @values.include?( v )
		end
		#
		def ==( o )
			return false if ! o.kind_of?(Variable)
			return @label == o.label && @values.to_set == o.values.to_set
		end
		#
		def eql?( o )
			return self == o
		end
		#
		def hash
			return to_s.hash
		end
	end # class Variable
end
