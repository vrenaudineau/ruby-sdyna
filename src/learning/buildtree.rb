# encoding: utf-8

require_relative "../data/example"

module SDYNA
	module Learning
		# Build and return a decision tree from \a examples list,
		# and mesurment function \m.
		def self.build_tree(node, examples)
			return node if examples.empty?
			node.examples = examples if node.respond_to?(:examples)
			
			# On vérifie si tous les sigmas sont identiques.
			if examples.all? { |e| e.sigma == examples.first.sigma }
				node.leaf = examples.first.sigma
			# Les sigmas sont différents, on va séparer
			else
				# On choisit la variable
				variables = examples.first.state.keys
				possibles = variables.reject do |var| node.path.key?(var) end
				raise "Error : Ne peut pas subdiviser plus. In #{path.inspect} with #{examples} : \n#{self}" if possibles.empty?
				var = examples.select_attr(possibles)
				# On l'affecte,
				node.test = var
				# On update les nouveaux enfants.
				for vi, exList in examples.separate(var)
					build_tree(node[vi], exList)
				end
			end
			return node
		end # def self.build_tree
	end # module Learning
end # module SDYNA
