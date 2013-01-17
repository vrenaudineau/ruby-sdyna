# encoding: utf-8

require_relative "../data/example"
require_relative "./buildtree"

module SDYNA
	module Learning
		# Update and return the decision tree \node with the new \a example
		# and mesurment function \m.
		def self.update_tree(node, e)
			raise ArgumentError if ! e.kind_of?(Example)
			node.examples << e
			examples = node.examples
			path = node.path
			
			# Si on a qu'un exemple, le nouveau, on l'attribut et on arrête.
			if node.leaf? && node.examples.size == 1
				node.leaf = e.sigma
			# si on est sur une feuille	(donc tout les sigmas sont identiques)
			# et que le nouvelle exemple colle, on arrête.
			elsif node.leaf? && node.examples.first.sigma == e.sigma
				# on ne fait rien
			# Sinon, si on a pas une feuille, ou que ça ne colle plus
			# on choisit la meilleure variable.
			else                                 
				# On choisit la variable
				variables = examples.first.state.keys
				possibles = variables.reject do |var| path.key?(var) end
				raise "Error : Ne peut pas subdiviser plus. In #{path.inspect} with #{e} : \n#{self}" if possibles.empty?
				var = examples.select_attr(possibles)
				
				# Si on testait déjà la même variable
				if node.test?(var)
					# On update l'enfant avec l'exemple.
					child = node[e.state[var]]
					update_tree(child, e)
				# Si on était sur une feuille, 
				# ou que la variable testée avant n'est plus la même
				else
					# On l'affecte
					node.test = var
					# On update les nouveaux enfants.
					for vi, exList in examples.separate(var)
						build_tree(node[vi], exList)
					end
				end
			end
			return node
		end # def self.update_tree
	end # module Learning
end # module SDYNA
