# encoding: utf-8

require_relative "../data/example"

module SDYNA
	module Learning
		# Build and return a decision tree from \a decision tree,
		# and mesurment function \mfct.
		def self.reorganise_tree(tree)
			examples = Examples.new
			for l in tree.leafs
				examples << Example.new(l.path, l.content)
			end
			return build_tree_f(tree, examples)
		end # def self.reorganise_tree
		
		def self.build_tree_f(node, examples)
			raise ArgumentError, "Examples list is empty : there must be at least one example." if examples.empty?
			
			# On vérifie si tous les sigmas sont identiques.
			if examples.all? { |e| e.sigma == examples.first.sigma }
				node.leaf = examples.first.sigma
			# Les sigmas sont différents, on va séparer
			else
				# On choisit la variable
				variables = examples.first.state.keys
				# On ne prend que les variables qui sont définies pour tous les exemples.
				examples.each do |e| variables &= e.state.keys end
				# On rejettes celles qui ont déjà été prises.
				possibles = variables.reject do |var| node.path.key?(var) end
				raise "Error : Ne peut pas subdiviser plus. In #{path.inspect} with #{examples} : \n#{self}" if possibles.empty?
				var = examples.select_attr(possibles)
				# On l'affecte,
				node.test = var
				# On update les nouveaux enfants.
				for vi, exList in examples.separate(var)
					build_tree_f(node[vi], exList)
				end
			end
			return node
		end # def self.build_tree_f
	end # module Learning
end # module SDYNA
