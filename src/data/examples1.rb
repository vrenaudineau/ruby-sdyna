# encoding: utf-8

require_relative "./variable"
require_relative "./potential"
require_relative "./example"

module SDYNA
	# Simple array.
	class Examples < Array
		#
		def diff_sig?(var, epsilon)
			return chi_deux(var) > epsilon
		end
		# X²
		def chi_deux(var)
			examples = self
			raise ArgumentError, "Wait a Variable for first argument, got a #{var.class}" if ! var.kind_of?(Variable)
			raise ArgumentError, "Wait an Array for second argument, got a #{examples.class}" if ! examples.kind_of?(Array)
			
			n = examples.size.to_f
			return 0.0 if n == 0.0
			
			# Examples dont sigma vaut s
			sigma_vers_examples = {}
			# Examples dont state[var] = vi
			vi_vers_examples = {}
			result = 0.0
			
			# On récupère les sigmas
			sigmas = examples.collect do |e| e.sigma end
			sigmas.uniq!
			# On récupère les examples par sigma
			sigma_vers_examples = examples.group_by do |e|
				e.sigma
			end
			# On récupère les examples par vi
			vi_vers_examples = examples.group_by do |e|
				e.state[var]
			end
			# On itère sur les sigma
			for sigma in sigmas
				# nb_ex4sig le nombre d'exemple pour ce sigma
				nb_ex4sig = (sigma_vers_examples[sigma].nil? ? 0 : sigma_vers_examples[sigma].size.to_f)
				# On itère sur les vi de var
				for vi in var
					# nb_ex4vi le nombre d'exemple pour ce vi
					nb_ex4vi = (vi_vers_examples[vi].nil? ? 0 : vi_vers_examples[vi].size.to_f)
					
					# nb_ex4viNsig le nombre d'exemple pour ce sigma et ce vi à la fois
					nb_ex4viNsig = if sigma_vers_examples[sigma].nil? || vi_vers_examples[vi].nil?
						0
					else
						(sigma_vers_examples[sigma] & vi_vers_examples[vi]).size.to_f
					end
					
					# On somme pour chaque sigma et chaque vi de var
					result += (nb_ex4viNsig - nb_ex4vi * nb_ex4sig / n)**2 /
					 (nb_ex4vi * nb_ex4sig / n) unless nb_ex4sig == 0 || nb_ex4vi == 0
				end
			end
			
			return result
		end
		#
		def select_attr(vars)
			return vars.max_by do |v| chi_deux(v) end
		end
		#
		def aggregate(var)
			raise ArgumentError, "Wait a Variable, got a #{var.class}." unless var.kind_of?(Variable)
			
			# On crée une Hash vi=>0.0
			p = Hash[ var.collect { |vi| [vi,0.0] } ]
			for e in self
				p[e.sigma] += 1.0
			end
			n = self.size.to_f
			p.each do |k,v|
				p[k] = v / n
			end
			res = Potential.new
			res[var] = p
			return res
		end	
		#
		def separate(var)
			h = self.group_by do |e|
				e.state[var]
			end
			for v, es in h
				h[v] = Examples.new(es) 
			end
			return h
		end
	end
end
