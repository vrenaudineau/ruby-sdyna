# encoding: utf-8
require_relative "variable"

module SDYNA
	# Une instanciation de variable(s) vers une de leur valeur possible
	class Instanciation
		#
		def Instanciation.from_hash(h)
			i = Instanciation.new
			h.each do |var,val|
				i[var] = val
			end
			return i
		end
		#
		def initialize
			@h = {}
			@next = nil
		end
		#
		def [](v)
			return @h[v]
		end
		# Set value u for Variable v. Return u.
		def []=(v, u)
			raise ArgumentError, "Wait a Variable, got a #{v.class}." unless v.kind_of?(Variable)
			raise ArgumentError, "La valeur en fait pas vartie du domaine de la variable" unless v.value?(u)
			@h[v] = u
			return u
		end
		# Same has []= but return self.
		def add(v, u)
			self[v] = u
			return self
		end
		#
		def each
			@h.each do |var,val|
				yield(var,val)
			end
			self
		end
		#
		def empty?
			return @h.empty?
		end
		#
		def has_var?(v)
			return @h.has_key?(v)
		end
		alias_method :key, :has_var?
		
		# L'ordre des variables est l'ordre d'insertion à la création
		# Passe à la prochaine valeur, jusqu'à ce que toutes les combinaisons aient été faites.
		# Retourne nil si c'est le cas.
		def next
			next? if @next.nil?
			@h, @next = @next, nil
			return self
		end
		#
		def next?
			try_to_inc = true
			@next = {}
			@h.to_a.reverse.each do |var,val|
				if try_to_inc
					idx = var.values.index( val )
					if idx+1 < var.size
						@next[var] = var.values[idx+1]
						try_to_inc = false
					else
						@next[var] = var.values.first
					end
				else
					@next[var] = @h[var]
				end
			end
			return ! try_to_inc
		end
		#
		def to_h
			return @h.dup
		end
		#	
		def to_s
			return @h.to_s
		end
		#
		def vars
			return @h.keys
		end
	end
	
	#
	class VarInst < Instanciation
		#
		def VarInst.from_hash(h)
			i = VarInst.new
			h.each do |var,val|
				i[var] = val
			end
			return i
		end
		# Set value u for Variable v. Return u.
		def []=(v, u)
			raise ArgumentError, "Wait a Variable, got a #{v.class}." unless v.kind_of?(Variable)
			raise ArgumentError, "La valeur en fait pas vartie du domaine de la variable" unless v.value?(u)
			@h[v] = u
			return u
		end
		# L'ordre des variables est l'ordre d'insertion à la création
		# Passe à la prochaine valeur, jusqu'à ce que toutes les combinaisons aient été faites.
		# Retourne nil si c'est le cas.
		def next
			next? if @next.nil?
			@h, @next = @next, nil
			return self
		end
		#
		def next?
			try_to_inc = true
			@next = {}
			@h.to_a.reverse.each do |var,val|
				if try_to_inc
					idx = var.values.index( val )
					if idx+1 < var.size
						@next[var] = var.values[idx+1]
						try_to_inc = false
					else
						@next[var] = var.values.first
					end
				else
					@next[var] = @h[var]
				end
			end
			return ! try_to_inc
		end
	end
end
