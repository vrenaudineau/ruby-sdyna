# encoding: utf-8

require_relative "./variable"
require_relative "./potential"
require_relative "./example"

module SDYNA
	# Save number of item foreach Variable/value/sigma.
	# Very usefull for chi_square.
	# Optimisé pour chi_deux et aggregation et separation
	# Pour le chi_deux on a besoin : 
	# -> du nombre d'exemple pour un var=>vi, peut importe les autre vars.
	# -> du nombre d'exemple pour un sigma, peut importe les autre vars.
	# -> du nombre d'exemple pour un sigma et un var=>vi, peut importe les autre vars.
	# Pour l'aggregation on a besoin :
	# -> du nombre d'exemple pour un sigma, peut importe les autre vars.
	# Pour la séparation on a besoin :
	# -> pour des exemples pour chaques chaque var=>vi
	# ==> Hash[Var=>Hash[vi=>Hash[sigma=>Integer]], sigma=>Integer]
	class Examples
		include Enumerable
		
		attr_accessor :size, :count, :sigmas
		attr_reader :vars, :first
		
		# On lui passe la liste des variables
		def initialize(examples=nil)
			@size = 0.0
			@count = {}
			@sigmas = {}
			@sigmas.default = 0.0
			@first = nil
			self << examples if examples
		end
		def initVars(e)
			if e.kind_of?(Example)
				@vars = e.state.keys
				@first = e
			elsif e.kind_of?(Examples)
				@vars = e.vars
				@first = e.first
			end
			@vars.each do |v|
				@count[v] = {}
				v.each do |vi|
					@count[v][vi] = {}
					@count[v][vi][:count] = 0.0
					@count[v][vi][:sigmas] = {}
					@count[v][vi][:sigmas].default = 0.0
					@count[v][vi][:examples] = []
				end
			end
		end
		def add(e)
			self << e
		end
		def empty?
			return @size == 0
		end
		def each
			for var in @vars
				for vi in var
					for e in @count[var][vi][:examples]
						yield e
					end
				end
			end
		end
		# examples << anExample
		# examples << [ofExample]
		# examples << examples
		def <<(e)
			if e.kind_of?(Example)
				initVars(e) if @vars.nil?
				@size += 1.0
				#~ e.state.each do |var,vi|
				@vars.each do |var|
					vi = e.state[var]
					@count[var][vi][:count] += 1.0
					@count[var][vi][:examples] << e
					@count[var][vi][:sigmas][e.sigma] += 1.0
				end
				@sigmas[e.sigma] += 1.0
			elsif e.kind_of?(Array)
				e.each do |ex|
					self << ex
				end
			elsif e.kind_of?(Examples)
				@vars = e.vars if @vars.nil?
				@size += e.size
				for var, hvi in e.count
					# Pour chaque Variable=>vi
					for vi, h in hvi
						@count[var][vi][:count] += h[:count]
						@count[var][vi][:examples] += h[:examples]
						# Pour chaque (Variable=>vi, sigma)
						for sig, nb in h[:sigmas]
							@count[var][vi][:sigmas][sig] += nb
						end
					end
				end
				for sig, val in @sigmas
					@sigmas[sig] += val
				end
			else
				raise ArgumentError, "Wait an Example or an Array of Example, got a #{e.class}" if ! e.kind_of?(Example)
			end
			return self
		end
		def uniq_sigma?
			return @sigmas.keys.size == 1
		end
		def separate(var)
			res = {}
			vars = @vars.dup
			vars.delete(var)
			for vi, h in @count[var]
				res[vi] = Examples.new(h[:examples])
			end
			return res
		end
		# X²
		def chi_deux(var)
			raise ArgumentError, "Wait a Variable for first argument, got a #{var.class}" if ! var.kind_of?(Variable)
			
			n = @size
			return 0.0 if n == 0.0			
			result = 0.0
			sigmas = @sigmas.keys
			
			# On itère sur les sigma
			for sig in sigmas
				# nb_ex4sig le nombre d'example pour ce sigma
				nb_ex4sig = @sigmas[sig] || 0.0
				# On itère sur les vi de var
				for vi in var
					# nb_ex4vi le nombre d'exemple pour ce vi
					nb_ex4vi = @count[var][vi][:count]
					# nb_ex4viNsig le nombre d'exemple pour ce sigma et ce vi à la fois
					nb_ex4viNsig = @count[var][vi][:sigmas][sig] || 0.0
					# On somme pour chaque sigma et chaque vi de var
					result += (nb_ex4viNsig - nb_ex4vi * nb_ex4sig / n)**2 /
					 (nb_ex4vi * nb_ex4sig / n) unless nb_ex4sig == 0.0 || nb_ex4vi == 0.0
				end
			end
			
			return result
		end
		#
		def aggregate(var)
			raise ArgumentError, "Wait a Variable, got a #{var.class}." unless var.kind_of?(Variable)
			# On crée une Hash vi=>0.0
			p = Hash[ var.collect { |vi| [vi,0.0] } ]
			for sig in @sigmas.keys
				p[sig] = @sigmas[sig] / @size
			end
			res = Potential.new
			res[var] = p
			return res
		end
		#
		def select_attr(vars)
			return vars.max_by do |v|
				chi_deux(v)
			end
		end
		#
		def diff_sig?(var, epsilon)
			return chi_deux(var) > epsilon
		end
	end
end
