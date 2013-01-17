# encoding: utf-8

require_relative "./variable"

module SDYNA
	#
	class Potential
		# h := {variable=>cpd}
		# variable := Variable | String
		# cpd := {value=>Float}
		# value := any object
		def Potential.from_hash(h)
			raise ArgumentError, "Wait a Hash, got a #{h.class}." unless h.kind_of?(Hash)
			p = Potential.new
			h.each do |var, h2|
				var = Variable.new(var, h2.keys) if var.kind_of?(String)
				p[var] = h2.dup
			end
			return p
		end
		# If a Variable or an Array of Variable is given,
		# initialize it with an uniform potential.
		def initialize(arg=nil)
			@p = {}
			if arg.kind_of?(Variable)
				@p[arg] = {}
				val = 1.0 / arg.size.to_f
				arg.each do |vi|
					@p[arg][vi] = val
				end				
			elsif arg.kind_of?(Array)
				arg.each do |v|
					@p[v] = {}
					val = 1.0 / v.size.to_f
					v.each do |vi|
						@p[v][vi] = val
					end				
				end
			end
		end
		#
		def [](arg)
			# [](arg : Variable) : Hash[U=>Float]
			if arg.kind_of?(Variable)
				raise ArgumentError, "#{arg} ne fait pas partie du Potential" if @p[arg].nil?
				return @p[arg].dup
			# [](arg : Hash) : Float
			elsif arg.kind_of?(Hash)
				res = 1.0
				for var,val in arg
					res *= @p[var][val] if @p.key?(var)
				end
				return res
			# [](arg : Array[Variable]) : Potential
			elsif arg.kind_of?(Array)
				#~ raise ArgumentError, "vars are different ! #{(arg - self.vars)} are not inside." if ! (arg - self.vars).empty?
				p = Potential.new
				arg.each do |var|
					p[var] = @p[var].dup
				end
				return p
			else
				raise ArgumentError, "Wait a Variable, a Hash or an Array of Variable, got a #{arg.class}."
			end
		end
		#
		def []=(var, val)
			raise ArgumentError, "Wait a Variable, got a #{var.class}." if ! var.kind_of?(Variable)
			raise ArgumentError, "#{self} contient déjà la variable #{var.label}" if @p.has_key?(var)
			raise ArgumentError, "Wait a Hash, got a #{val.class}." if ! val.kind_of?(Hash)
			raise ArgumentError, "p's xi are different of x's xi : #{val.keys} and #{var.values} for #{var.label}" if val.keys.to_set != var.values.to_set
			r = 0.0
			val.each do |xi,v|
				r += v
			end
			raise ArgumentError, "Proba must some to 1.0" if r != 1.0
			@p[var] = val.dup
			return val
		end
		# == @p union o.@p. Si une var existe dans les deux prend celle de o.
		def *(o)
			raise ArgumentError, "Wait a Potential, got a #{o.class}." if ! o.kind_of?( Potential )
			res = o.clone
			for var,p in @p
				res[var] = p.dup unless res.has_var?(var)
			end
			return res
		end
		#
		def ==(o)
			return false if ! o.kind_of?(Potential) || self.vars.to_set != o.vars.to_set
			return @p.all? do |var,h2|
				o[var] == h2
			end
		end
		# Same as []= but return self.
		def add(var,val)
			self[var] = val
			return self
		end
		#
		def clone
			res = Potential.new()
			for var,h2 in @p
				res[var] = h2.dup
			end
			return res
		end
		#
		def has_var?(v)
			return @p.key?(v)
		end
		#
		def to_s
			s = @p.collect do |var,h|
				"#{var.inspect}=>#{h.inspect}"
			end
			return "Pot#{s.inspect}"
		end
		#
		def vars
			return @p.keys
		end
	end
end
