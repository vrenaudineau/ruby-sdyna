# encoding: utf-8
require_relative "variable"
require_relative "potential"

module SDYNA
	#
	class Exemple
		#
		def Exemple.diff_sig?(exemples, var, epsilon)
			return Exemple.chi_deux(exemples, var) > epsilon
		end
		# X²
		def Exemple.chi_deux(exemples, var)
			raise ArgumentError, "Wait a Variable for first argument, got a #{var.class}" if ! var.kind_of?(Variable)
			raise ArgumentError, "Wait an Array for second argument, got a #{exemples.class}" if ! exemples.kind_of?(Array)
			
			n = exemples.size.to_f
			return 0.0 if n == 0.0
			
			# Exemples dont sigma vaut s
			sigma_vers_exemples = {}
			# Exemples dont state[var] = vi
			vi_vers_exemples = {}
			result = 0.0
			
			# On récupère les sigmas
			sigmas = exemples.collect do |e| e.sigma end
			sigmas.uniq!
			# On itère sur les sigma
			for sigma in sigmas
				# On récupère les exemples qui correspondent à ce sigma
				sigma_vers_exemples[sigma] = exemples.select do |e|
					e.sigma == sigma
				end
				# nb_ex4sig le nombre d'exemple pour ce sigma
				nb_ex4sig = sigma_vers_exemples[sigma].size.to_f
				
				# On itère sur les vi de var
				for vi in var
					# On récupère les exemples qui correspondent à ce vi si ce n'est pas déjà fait
					vi_vers_exemples[vi] ||= exemples.select do |e|
						e.state[var] == vi
					end
					# nb_ex4vi le nombre d'exemple pour ce vi
					nb_ex4vi = vi_vers_exemples[vi].size.to_f
					
					# nb_ex4viNsig le nombre d'exemple pour ce sigma et ce vi à la fois
					nb_ex4viNsig = (sigma_vers_exemples[sigma] & vi_vers_exemples[vi]).size.to_f
					
					# On somme pour chaque sigma et chaque vi de var
					result += (nb_ex4viNsig - nb_ex4vi * nb_ex4sig / n)**2 /
					 (nb_ex4vi * nb_ex4sig / n) unless nb_ex4sig == 0 || nb_ex4vi == 0
				end
			end
			
			return result
		end
		#
		def Exemple.select_attr( exemples, vars )
			# Pour chaque variable
			chi = {}
			return vars.max do |v1,v2|
				chi[v1] ||= Exemple.chi_deux(exemples, v1)
				chi[v2] ||= Exemple.chi_deux(exemples, v2)
				chi[v1] <=> chi[v2]
			end
		end
		#
		def Exemple.aggregate( exemples, var )
			raise ArgumentError, "Wait a Variable, got a #{var.class}." unless var.kind_of?(Variable)
			# On crée une Hash vi=>0.0
			p = Hash[ var.collect do |vi| [vi,0.0] end ]
			for e in exemples
				p[e.state[var]] += 1.0
			end
			n = exemples.size.to_f
			p.each do |k,v|
				p[k] = v / n
			end
			res = Potential.new
			res[var] = p
			return res
		end	

		attr_reader :state , :sigma
		#
		def initialize( state, sigma )
			@state, @sigma = state, sigma
		end
		#
		def to_s
			return "#{@state.inspect}=>#{sigma.inspect}"
		end
	end # class Exemple
end
