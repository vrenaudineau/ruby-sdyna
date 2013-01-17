# encoding: utf-8

require_relative "./variable"
require_relative "./tree"
require_relative "../learning/buildtreef"

module SDYNA
	# The main class.
	# A FMDP contains a list of Variables, some possible Actions,
	# a TransitionTree by tuple of Variable/Action,
	# a ValueTree per Action, a global ValueTree and a RewardTree.
	class FMDP
		attr_accessor :transitions, :value, :rewards, :q
		attr_reader :variables, :actions
		
		def initialize(variables, actions)
			# Contient la liste des variables
			if variables.kind_of?(Hash)
				@variables = variables.collect do |label, values|
					Variable.new(label,values)
				end
			elsif variables.kind_of?(Array)
				@variables = variables
			end
			
			# Contient la liste des actions
			@actions = actions
			
			# Contient le tableau des transitions. Un arbre par action et par variable.
			@transitions = {}
			for a in @actions
				@transitions[a] = {}
				for v in @variables
					@transitions[a][v] = TransitionTree.new(v)
				end
			end
			# Arbre des récompenses
			@rewards = RewardTree.new(0)
			# Arbre de la valeur espérée pour un état.
			@value = ValueTree.new(0)
			
			# Traite les actions possibles comme les valeurs possible d'une Variable
			@varAction = Variable.new(:actions, @actions)
			# Hash[Action => Tree[Float]
			# Pour chaque action, valeur future espérée dans un état donné.
			@q = {}
		end # FMDP.initialize
		
		#
		def inspect
			return "FMDP<#{@variables.size} vars, #{@actions.size} actions>"
		end
		
		#
		def policy
			p = PoliticTree.new.init_copy(@value)
			@value.leafs.each do |l|
				path = l.path
				a = @actions.max_by { |a|
					c = @q[a][path]
					# On tombe pas forcément sur une feuille, 
					# mais après simplification dans le contexte oui
					# si c'est un max
					c = c.clone.simplify!(path) if ! c.leaf?
					if c.leaf?
						c.content
					else
						0.0
					end
				}
				p[path].leaf = a
			end
			return Learning.reorganise_tree( p.simplify! )
		end # def policy
		
		#
		def to_s
			s  = "~~~~~~~~~~~~~~~~~~~~        FMDP        ~~~~~~~~~~~~~~~~~~~~\n"
			s += "Variables  :\n"
			@variables.each do |v|
				s += "\t#{v}\t: #{v.values.join(", ")}\n"
			end
			s += "Actions :#{@actions.join(", ")}\n"
			s += "Récompenses :\n"
			s += @rewards.to_s+"\n"
			s += "Transitions :\n"
			@transitions.each do |action,v|
				v.each do |var, tree|
					s += ">>>> For [#{action}][#{var.label}] :\n"
					s += tree.to_s+"\n"
				end
			end
			s += "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
			return s
		end # def to_s
	end # class FMDP
end # module SDYNA
