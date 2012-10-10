# encoding: utf-8
require_relative "variable"
require_relative "instanciation"
require_relative "potential"
require_relative "exemple"
require_relative "node"

module SDYNA
	class FMDP
		attr_accessor :gamma, :epsilon, :transitions, :valeur, :recompenses
		attr_reader :valeurMaxComb, :variables, :actions
		
		def initialize(variables, actions)
			# Contient la liste des variables
			@variables = variables.collect do |label, values|
				Variable.new(label,values)
			end
			# Contient la liste des actions
			@actions = actions
			# Contient le tableau des transitions. Un arbre par action et par variable.
			@transitions = {}
			for a in @actions
				@transitions[a] = {}
				for v in @variables
					@transitions[a][v] = Tree.new
					# On calcul le Potential uniforme initial
					p = {}
					v.each do |vi|
						p[vi] = 1.0/v.size.to_f
					end
					# Potential initial
					@transitions[a][v].set_leaf(Potential.from_hash({v=>p}))
				end	
			end
			# Arbre des récompenses
			@recompenses = Tree.new().set_leaf(1)
			# Arbre de la valeur espérée pour un état.
			@valeur = Tree.new().set_leaf(1)
			# Utilisé pour le calcul des gains futurs. Voir regress.
			@gamma = 0.9
			# Voir Exemple.diff_sig.
			@epsilon = 10
			
			# Traite les actions possibles comme les valeurs possible d'une Variable
			@varAction = Variable.new(:actions,@actions)
			# Hash[Action => Tree[Float]
			# Pour chaque action, valeur future espérée dans un état donné.
			@q = {}
		end # FMDP.initialize
		
		# Fonction de combinaison des valeurs pour les feuilles des arbres.
		ValeurMaxComb = Proc.new do |v1,v2|
			raise ArgumentError, "Wait 2 Numeric, got #{v1.class} and #{v2.class}" if ! v1.kind_of?( Numeric ) || ! v2.kind_of?( Numeric )
			[v1, v2].max
		end
		RecompensesAddComb = Proc.new do |v1,v2| 
			raise ArgumentError, "Wait 2 Numeric, got #{v1.class} and #{v2.class}" if ! v1.kind_of?( Numeric ) || ! v2.kind_of?( Numeric )
			v1 + v2
		end
		TransitionsMultComb = Proc.new do |v1,v2|
			raise ArgumentError, "Wait 2 Potential, got #{v1.class} and #{v2.class}" if ! v1.kind_of?( Potential ) || ! v2.kind_of?( Potential )
			v1 * v2
		end
			
		# Calcule P(s'|s,a) pour chaque s'
		def p_regress(node, a)
			# 1.
			return Tree.new if node.leaf?
			
			# 3.
			pchild = {}
			for vi, child in node.branchesAndChildren
				pchild[vi] = p_regress(child, a)
			end
			
			# 2. et 4. L'arbre des transitions de la var X pour l'action a
			raise if @transitions[a][node.test].nil?
			p = @transitions[a][node.test].clone
			
			# 5.
			for l in p.leafs
				# (a)
				list = []
				for vi in node.branches
					list << pchild[vi] if ! pchild[vi].empty? && l.content[{node.test=>vi}] > 0 # La proba dans l quand x = v
				end
				# (b)
				if ! list.empty?
					m = Tree.merge( list, FMDP::TransitionsMultComb )
					l.append!( m, FMDP::TransitionsMultComb )
				end
			end
			
			return p
		rescue => err
			puts "in FMDP::p_pegress : node=\n#{node}\n @transitions[#{a}][#{node.test.label}]=\n#{@transitions[a][node.test].inspect}"
			raise err
		end # FMDP.p_regress

		# Moduleur d'espérance
		attr_accessor :gamma
		
		#
		def regress(a)
			# 1.
			p = p_regress(@valeur, a).simplify!
			p.set_leaf(Potential.new) if p.empty?
			# 2.
			for l in p.leafs
				# (a).
				pb = l.content
				# (b).
				v = 0
				@valeur.leafs.each do |vbp| # vbp pour V(b')
					pathToHash = vbp.path
					v += vbp.content * pb[pathToHash]
				end
				# (c). + 3.
				l.set_leaf(@gamma*v)
			end
			# 4.
			return @recompenses.clone.append!(p, FMDP::RecompensesAddComb).simplify!
		rescue => err
			puts "in FMDP::regress : a=#{a}, @valeur=\n#{@valeur}\np=\n#{p}"
			raise err
		end # FMDP.regress
		#
		def update_tree2(node, exempl)
			path = node.path
			
			# Si on nous passe un ensemble d'exemple, c'est qu'on vient de faire une séparation.
			if exempl.kind_of?(Array)
				node.exemples = exempl
				# On vérifie si tous les sigmas sont identiques.
				sigma = exempl.first.sigma
				if exempl.all? { |ex| ex.sigma == sigma }
					node.set_leaf(sigma)
				# Les sigmas sont différents, on va séparer
				else
					# On choisit la variable
					possibles = @variables.reject do |var| path.key?(var) end
					raise "Error : Ne peut pas subdiviser plus. In #{path.inspect} with #{exempl} : \n#{self}" if possibles.empty?
					var = Exemple.select_attr( exempl, possibles )
					# On l'affecte,
					node.set_test(var)
					# On update les nouveaux enfants.
					for vi, exList in exempl.group_by { |ex| ex.state[var] }
						update_tree2(node[vi], exList)
					end
				end	
			# Sinon, si on a qu'un exemple
			else
				raise ArgumentError if ! exempl.kind_of?(Exemple)
				node.exemples << exempl
				
				# Si on a qu'un exemple, le nouveau, on l'attribut et on arrête.
				if node.leaf? && node.exemples.size == 1
					node.set_leaf(exempl.sigma)
				# si on est sur une feuille	(donc tout les sigmas sont identiques)
				# et que le nouvelle exemple colle, on arrête.
				elsif node.leaf? && node.exemples.first.sigma == exempl.sigma
					# on ne fait rien
				# Sinon, si on a pas une feuille, ou que ça ne colle plus
				# on choisit la meilleure variable.
				else
					possibles = @variables.reject do |var| path.key?(var) end
					raise "Error : Ne peut pas subdiviser plus. In #{path.inspect} with #{exempl} : \n#{self}" if possibles.empty?
					var = Exemple.select_attr( node.exemples, possibles )
					
					# Si on testait déjà la même variable
					if node.test?(var)
						# On update l'enfant avec l'exemple.
						child = node[exempl.state[var]]
						update_tree2(child, exempl)
					# Si on était sur une feuille, 
					# ou que la variable testée avant n'est plus la même
					else
						# On l'affecte
						node.set_test(var)
						# On update les nouveaux enfants.
						for vi, exList in node.exemples.group_by { |ex| ex.state[var] }
							update_tree2(node[vi], exList)
						end
					end
				end
			end
		end # def FMDP.update_tree2
		#
		def update_tree(node, newExemple)
			# 1.
			es = node.exemples
			es << newExemple
			path = node.path
			
			# 2.
			if node.leaf? && (es.size == 1 || newExemple.sigma == es.first.sigma)
				node.set_leaf( newExemple.sigma ) if es.size == 1
			else
				# (a).
				possibles = (@variables+[@varAction]).reject do |var| path.key?(var) end
				raise "Error : Ne peut pas subdiviser plus. In #{path.inspect} with #{newExemple} : \n#{self}" if possibles.empty?
				var = Exemple.select_attr( es, possibles )
				
				# (b).
				if node.test?(var)
					child = node[newExemple.state[var]]
					update_tree(child, newExemple)
				else
					# i. et ii.
					node.set_test(var)
					# iii.
					for e in es
						update_tree(node[e.state[var]], e)
					end
				end
			end
		rescue => err
			puts "in FMDP::update_tree : node=#{node.test}, newExemple=#{newExemple}"
			raise err
		end # FMDP.update_tree

		#
		def update_tree_s2(node, varTrans, e)
			path = node.path
			
			# Si on nous passe un ensemble d'exemple, c'est qu'on vient de faire une séparation.
			if e.kind_of?(Array)
				node.exemples = e
				exemples = node.exemples

				# On récupère la meilleure variable
				possibles = @variables.reject do |v| path.key?(v) end
				raise "Error : Ne peut pas subdiviser plus. In #{path.inspect} with #{exemples} : \n#{self}" if possibles.empty?
				var = Exemple.select_attr(exemples, possibles)
				
				# Si la différence n'est pas signifcative
				if ! Exemple.diff_sig?(exemples, var, @epsilon)
					node.set_leaf( Exemple.aggregate(exemples, varTrans) )
				else
					# On l'affecte,
					node.set_test(var)
					# On update les nouveaux enfants.
					for vi, exList in exemples.group_by { |ex| ex.state[var] }
						update_tree_s2(node[vi], varTrans, exList)
					end
				end
			# Sinon, si on a qu'un exemple
			else
				raise ArgumentError if ! e.kind_of?(Exemple)
				node.exemples << e
				exemples = node.exemples
				
				var = node.test
				possibles = nil
				# On calcule la variable la plus discriminante si on en avait pas déjà une.
				if var.nil?
					possibles = @variables.reject do |v| path.key?(v) end
					raise "Error : Ne peut pas subdiviser plus. In #{path.inspect} with #{e} : \n#{self}" if possibles.empty?
					var = Exemple.select_attr(node.exemples, possibles)
				end
				# Si la variable n'est pas suffisemment discriminante
				if ! Exemple.diff_sig?(node.exemples, var, @epsilon)
					# Si ce n'est pas la variable qu'on testait déjà qui n'était pas suffisante
					if node.test.nil?
						# On aggrège.
						node.set_leaf( Exemple.aggregate(node.exemples, varTrans) )
					else
						# Sinon on recherche la meilleure variable.
						update_tree_s2(node, varTrans, exemples)
					end
				# Si elle est suffisemment discriminante
				else
					# Si on testait déjà cette variable
					if node.test?(var)
						child = node[e.state[var]]
						update_tree_s2(child, varTrans, e)
					else
						# On l'affecte
						node.set_test(var)
						# On update les nouveaux enfants.
						for vi, exList in exemples.group_by { |ex| ex.state[var] }
							update_tree_s2(node[vi], varTrans, exList)
						end
					end
				end
			end
		end # def FMDP.update_tree_s2
		#
		def update_tree_s( node, var, newExemple )
			# 1.
			es = node.exemples
			es << newExemple
			npath = node.path
			
			# 2.
			varToTest = node.test
			possibles = nil
			if varToTest.nil?
				possibles = (@variables).reject do |var| npath.key?(var) end # +[@varAction]
				raise "Error : Ne peut pas subdiviser plus. In #{npath.inspect} with #{newExemple} : \n#{self}" if possibles.empty?
				varToTest = Exemple.select_attr( es, possibles )
			end
			
			if ! Exemple.diff_sig?(es, varToTest, @epsilon)
				node.set_leaf( Exemple.aggregate(es, var) )
			else
				# (a).
				possibles ||= (@variables).reject do |var| npath[var] end # +[@varAction]
				raise "Error : Ne peut pas subdiviser plus. In #{npath.inspect} with #{newExemple} : \n#{self}" if possibles.empty?
				v = Exemple.select_attr( es, possibles )
				# (b).
				if v == node.test
					child = node[newExemple.state[v]]
					update_tree_s(child, var, newExemple)
				else
					node.set_test(v)
					for e in es
						update_tree_s(node[ e.state[v] ], var, e)
					end
				end
			end
		rescue => err
			puts "in FMDP::update_tree_s : node=#{node.test}, var=#{var.label}, newExemple=#{newExemple}"
			raise err
		end # FMDP.update_tree_s
		
		#
		def updateFMDP( s, a, sp, r )
			# Update les transtions lorsqu'on fait l'action a dans l'état s
			for v in @variables
				update_tree_s2(@transitions[a][v], v, Exemple.new(s, sp[v]))
			end
			# Update les récompenses, qui ne sont fonction que de l'état atteint.
			update_tree2(@recompenses, Exemple.new( sp.clone, r )) # .clone.update({:action=>a})
		rescue => err
			puts "in FMDP::updateFMDP : s=#{s}, a=#{a}, sp=#{sp}, r=#{r}"
			raise err
		end # FMDP.updateFMDP
		
		#
		def incSVI()
			for a in @actions
				@q[a] = regress(a)
			end
			@valeur = Tree.merge( @actions.collect { |a| @q[a] }, FMDP::ValeurMaxComb ) # avec max
		end # FMDP.incSVI
		
		def observe(s, a, sp, r)
			updateFMDP(out2in(s), a, out2in(sp), r)
			incSVI()
		rescue => err
			puts "in FMDP::observe : s=#{s}, a=#{a}, sp=#{sp}, r=#{r}\n" + to_s
			raise err
		end # FMDP.observe
		
		def act(cs)
			currentState = out2in(cs)
			if rand() < 0.2
				a = @actions[rand(@actions.size)]
				return a
			else
				list = []
				max = (-1.0/0) # -Inf
				@actions.each do |a|
					v = (if ! @q[a].nil? then @q[a].content_for(currentState) else 0 end)
					if v > max
						list = [a]
						max = v
					elsif v == max
						list << a
					end
				end
				a = list[rand(list.size)]
				return a
			end
		end # FMDP.act
		
		#
		def in2out(s)
			s.each do |var,vi|
				s.delete(var)
				s[var.label] = vi
			end
			return s
		end
		
		#
		def out2in(s)
			res = {}
			s.each do |label,vi|
				var = @variables.find do |v|
					v.label == label
				end
				res[var] = vi
			end
			return res
		end
		
		def politique
			return "wait"
		end
		
		def to_s
			s  = "~~~~~~~~~~~~~~~~~~~~        FMDP        ~~~~~~~~~~~~~~~~~~~~\n"
			s += "Variables  :\n"
			@variables.each do |v|
				s += "\t#{v}\t: #{v.values.join(", ")}\n"
			end
			s += "Actions :#{@actions.join(", ")}\n"
			s += "Récompenses :\n"
			s += @recompenses.to_s+"\n"
			s += "Transitions :\n"
			@transitions.each do |action,v|
				v.each do |var, tree|
					s += ">>>> For [#{action}][#{var.label}] :\n"
					s += tree.to_s+"\n"
				end
			end
			s += "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
			return s
		end # FMDP.to_s
	end # class FMDP
end
