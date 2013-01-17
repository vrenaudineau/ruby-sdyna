# encoding: utf-8

require_relative "./data/fmdp"
require_relative "./learning"
require_relative "./planning"
require_relative "./acting"

module SDYNA
	class AbstractSdyna
		attr_accessor :fmdp
		
		def initialize(vars, actions)
			@fmdp = FMDP.new(vars, actions)
		end
		
		def run(nbLoop, initState=nil, verbose=false)
			s = initState
			if s.nil?
				s = Hash[ @fmdp.variables.collect do |v|
					[v, v.sample]
				end ]
			end
			i = 0
			while ! self.done?(i, verbose) && i < nbLoop
				print "%2d%%" % (i*100/nbLoop) if verbose
				s = sdyna(s, verbose)
				i += 1
				print "\b\b\b" if verbose
			end
			print "   \b\b\b" if verbose
			return s
		end
		
		def run2(nbLoop, nbPerLoop, verbose=false)
			n = nbLoop * nbPerLoop
			nbLoop.times do |l|
				s = newInitState()
				i = 0
				while ! self.done?(i, verbose) && i < nbPerLoop
					print "%2d%%" % ((l*nbPerLoop+i)*100/n) if verbose
					s = sdyna(s, verbose)
					print "\b\b\b" if verbose
					i += 1
				end
			end
			print "   \b\b\b" if verbose
			return
		end
		
		def sdyna(s, verbose)
			# Decision
			a = self.decide(s, verbose)
			# Execution
			sp, r = self.exec(s, a, verbose)
			# Learning
			self.learn(s, a, sp, r, verbose)
			# Planning
			self.plan(verbose)
			return sp
		end
	end
	
	# This is an abstract base class.
	# You must reimplement \a exec method.
	# In initialize, call super with the list of observable variables and actions,
	# then call run. When done, you can :
	# - get the best action to do by calling the Acting.greedy method with the fmdp;
	# - get the policy by calling fmdp.policy.
	class Sdyna < AbstractSdyna
		# You may implement method for these parameters.
		attr_accessor :gamma4incSVI, :epsilon4greedy, :diffEpsilon4chiSquare
		attr_accessor :rewardDependsOfAction, :reorganiseValue
		
		# You may call super with vars and actions in argument.
		# \a vars a list of Variable, \a actions a list of Action.
		def initialize(vars, actions)
			# TODO : probème avec les paramètres un peu partout, en argument de fonction, dans fmdp, etc.
			super(vars, actions)
			@epsilon4greedy = 0.3
			@rewardDependsOfAction = false
			@gamma4incSVI = 0.9
			@diffEpsilon4chiSquare = vars.collect { |v| v.size }.inject :*
			@reorganiseValue = true
		end
		
		def decide(s, verbose)
			return Acting.e_greedy(@fmdp, s, epsilon4greedy)
		end
		
		# You must reimplement this method to compute new states and rewards.
		# \s is the previous state,
		# \a is the action to do in the state \s.
		# Return a cuple : the new state updated and the reward.
		def exec(s, a, verbose)
			raise "You must implemente this method."
			return {}, 0
		end
		
		def learn(s, a, sp, r, verbose)
			# Update les transtions lorsqu'on fait l'action a dans l'état s
			for v in fmdp.variables
				Learning.update_tree_s(@fmdp.transitions[a][v], Example.new(s, sp[v]), v, diffEpsilon4chiSquare)
			end

			# Update les récompenses, qui ne sont fonction que de l'état courant
			e = Example.new(s.clone, r)
			# et éventuellement de l'action réalisée.
			e.state.update({:action=>a}) if rewardDependsOfAction
			# Update le modèle de récompenses
			Learning.update_tree(@fmdp.rewards, e)
		end
		
		def plan(verbose)
			Planning.incSVI(@fmdp, gamma4incSVI)
			Learning.reorganise_tree(fmdp.value) if reorganiseValue
		end
		
		# Default implementation return always false, ie only nbIteration count.
		def done?(i, verbose)
			return false
		end
	end
end # module SDYNA
