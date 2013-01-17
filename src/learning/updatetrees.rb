# encoding: utf-8

require_relative "../data/example"
require_relative "./buildtrees"

module SDYNA
	module Learning
		# Update and return the stochastic decision tree \node with the new \a example
		# and mesurment function \m.
		def self.update_tree_s(node, example, varTrans, diffEpsilon)
			raise ArgumentError if ! example.kind_of?(Example)
			node.examples << example
			examples = node.examples
			path = node.path
			
			# Si feuille
				# calcule la meilleure var
				# si nil ou pas discri
					# leaf
				# sinon
					# affecte
			# sinon (var != nil)
				# si pas discri
					# calcule la meilleure var
					# si c'est la même
						# leaf
					# sinon
						# affecte
			
			# calcul bestVar
			variables = example.state.keys
			possibles = variables.reject do |v| path.key?(v) end
			bestVar = examples.select_attr(possibles) if ! possibles.empty?
			# Si la variable n'est pas suffisemment discriminante
			if ! examples.diff_sig?(bestVar, diffEpsilon)
				node.leaf = examples.aggregate(varTrans)
			# Sinon si on testait déjà cette variable
			elsif node.test?(bestVar)
				# On update l'enfant avec l'exemple.
				child = node[example.state[bestVar]]
				update_tree_s(child, example, varTrans, diffEpsilon)
			else
				# On l'affecte
				node.test = bestVar
				# On update les nouveaux enfants.
				for vi, exList in examples.separate(bestVar)
					build_tree_s(node[vi], exList, varTrans, diffEpsilon)
				end
			end
			
			return node
			
			var = node.test
			# On calcule la variable la plus discriminante si on en avait pas déjà une.
			if node.leaf?
				variables = example.state.keys
				possibles = variables.reject do |v| path.key?(v) end
				var = examples.select_attr(possibles) if ! possibles.empty?
			end
			# Si il ne reste plus de variable ou si la variable n'est
			# pas suffisemment discriminante
			if var.nil? || ! examples.diff_sig?(var)
				# Si ce n'est pas la variable qu'on testait déjà qui n'était pas suffisante
				if node.test.nil?
					# On aggrège.
					node.leaf = examples.aggregate(varTrans)
				else
					# Sinon on recherche la meilleure variable.
					update_tree_s(node, examples, varTrans)
				end
			# Sinon, si on a pas une feuille, ou que ça ne colle plus
			# on choisit la meilleure variable.
			else
				# Si on testait déjà la même variable
				if node.test?(var)
					# On update l'enfant avec l'exemple.
					child = node[example.state[var]]
					update_tree_s(child, example, varTrans)
				# Si on était sur une feuille, 
				# ou que la variable testée avant n'est plus la même
				else
					# On l'affecte
					node.test = var
					# On update les nouveaux enfants.
					for vi, exList in examples.separate(var)
						build_tree_s(node[vi], exList, varTrans)
					end
				end
			end
			return node
		end # def self.update_tree_s
	end # module Learning
end # module SDYNA
