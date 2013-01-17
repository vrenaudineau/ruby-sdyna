# encoding: utf-8

require_relative "../data/example"
require_relative "./buildtrees"

module SDYNA
	module Learning
		# Build and return a stochastic decision tree from \a examples list,
		# and mesurment function \m.
		def self.build_tree_s(node, examples, varTrans, sig)
			return node if examples.empty?
			node.examples = examples if node.respond_to?(:examples)
			
			variables = examples.first.state.keys
			
			# On récupère la meilleure variable
			possibles = variables.reject do |v| node.path.key?(v) end
			var = (if possibles.empty?
				nil
			else
				examples.select_attr(possibles)
			end)

			# Si la différence n'est pas signifcative
			if var.nil? || ! examples.diff_sig?(var, sig)
				node.leaf = examples.aggregate(varTrans)
			# Les sigmas sont différents, on va séparer
			else
				# On l'affecte,
				node.test = var
				# On update les nouveaux enfants.
				for vi, exList in examples.separate(var)
					build_tree_s(node[vi], exList, varTrans, sig)
				end
			end	
			return node
		end # def self.build_tree_s
	end # module Learning
end # module SDYNA
