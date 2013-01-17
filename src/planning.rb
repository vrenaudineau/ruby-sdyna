# encoding: utf-8

require_relative "./data/fmdp"

module SDYNA

	# Regroup planning functions
	# Call Planning.incSVI(fmdp) to performe a pass.
	module Planning
	
		# Perform a pass in computing and updating \a fmdp's Q and Value functions 
		# using the actual Transitions and Rewards functions.
		def self.incSVI(fmdp, gamma)
			for a in fmdp.actions
				fmdp.q[a] = regress(fmdp, a, gamma)
			end
			fmdp.value = ValueTree.merge(fmdp.actions.collect { |a| fmdp.q[a] }, false)
		end # def self.incSVI
		
		# Calcule P(s'|s,a) pour chaque s'
		# \f fmdp a FMDP, \a node a ValueNode, \a a an Action.
		# Return a TranstionNode.
		def self.p_regress(fmdp, node, a)
			# 1.
			return TransitionNode.new if node.leaf?
			
			# 3.
			pxi = {}
			for vi, child in node
				pxi[vi] = p_regress(fmdp, child, a)
			end
			
			# 2. et 4. L'arbre des transitions de la var X pour l'action a
			raise if fmdp.transitions[a][node.test].nil?
			p = fmdp.transitions[a][node.test].clone
			
			# 5.
			for l in p.leafs
				pl = l.content
				# (a)
				list = []
				for vi in node.branches
					list << pxi[vi] if ! pxi[vi].empty? && pl[node.test=>vi] > 0 # La proba dans pl quand x = v
				end
				# (b)
				if ! list.empty?
					m = list.pop.merge!(list)
					l.append!(m,false)
				end
			end
			
			return p
		end # def p_regress
		
		# \a fmdp a FMDP, \a a an Action, \a gamma the futur coefficient.
		# Return a ValueTree.
		def self.regress(fmdp, a, gamma)
			# 1.
			pa = p_regress(fmdp, fmdp.value, a).simplify!
			pa.leaf = Potential.new if pa.empty?
			# 2.
			paV = fmdp.value.class.new.init_copy(pa)
			for l in paV.leafs
				#b = l.path # b the branch
				# (a).
				pb = l.content # Potential
				# (b).
				vb = 0 # vb
				for lp in fmdp.value.leafs
					bp = lp.path # b' : Hash[Var=>vi]
					pbp = pb[bp] # Pb(b') : Float
					vbp = lp.content # V(b') : Float
					vb += vbp * pbp # vb = Pb(b')*V(b') : Float
				end
				# (c). + 3.
				l.leaf = gamma*vb
			end
			# 4.
			r = fmdp.rewards.clone.append!(paV).simplify!
			return fmdp.value.class.new.init_copy(r)
		end # def self.regress
	end # module Planning
end # module SDYNA
