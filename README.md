# ruby-sdyna

SDYNA is an algorithm to do reinforcement learning in Factorized Markov Decision Process (FMDP).

It has first been done by [Thomas Degris](http://people.bordeaux.inria.fr/degris/) in his thesis 
[Apprentissage par Renforcement dans les Processus de Décision Markoviens Factorisés. (2007)](http://people.bordeaux.inria.fr/degris/papers/These_Thomas_Degris.pdf)

## Installation
	gem build ruby-sdyna.gemspec
	sudo gem install ruby-sdyna-X.X.X.gem

## Documention
Just enter
	rdoc
the documentation will be generated in the doc/ folder.

## Usage Examples
	require "sdyna"
	
	# To not remention the module's name.
	include SDYNA
	
	# Create a new subclass of SDYNA::Sdyna
	class MyProblem < Sdyna
		attr_reader :off, :hoc, :hrc
		
		# We describe the problem and the parameters in initialize.
		def initialize
			# We create all the SDYNA::Variable of the problem,
			@off = Variable.new("off", [true, false])
			@hoc = Variable.new("hoc", [true, false])
			@hrc = Variable.new("hrc", [true, false])
			# the possibles actions,
			@actions = ["go","buy","del"]
			# and we give them to super.
			# The correct SDYNA::FMDP is created.
			super([@off, @hoc, @hrc], @actions)
			
			# SDYNA::Sdyna propose some default parameters.
			@epsilon4greedy = 0.3
			@rewardDependsOfAction = false
			@gamma4incSVI = 0.9
			@diffEpsilon4chiSquare = 20
			@reorganiseValue = false
		end
		
		# Then we redefined exec to fit our problem world.
		# This function take the current state \s, the action to do \a
		# and return the new state and the corresponding reward.
		def exec(s, a, verbose)
			newState = s.clone
			r = 0
			r += 10 if s[@hoc]
			newState[@hoc] = false
			case a
				when "go"
					newState[@off] = ! s[@off]
				when "buy"
					newState[@hrc] = (s[@hrc] || ! s[@off])
				when "del"
					newState[@hrc] = false
					newState[@hoc] = s[@off] && s[@hrc]
			end
			return newState, r
		end
		
		# We can also redefine newInitState to be used in run2.
		def newInitState
			return {
				@off => rand() < 0.5,
				@hoc => rand() < 0.2,
				@hrc => rand() < 0.3
			}
		end
	end
	
	# We create an instance of the problem,
	myPb = MyProblem.new
	
	# and run it ! We only give the number of iteration the algorithm must do.
	myPb.run(1000)
	# We can also call run2. The difference is that the algorithm restart 
	# to a new initial state by calling MyProblem.newInitState() each 50 iterations,
	# 20 times. 
	myPb.run2(20, 50)
	
	# Then we can retrieve the learned model.
	fmdp = myPb.fmdp
	
	# Now we can view the transition model,
	puts fmdp.transitions["del"][myPb.hoc]
	
	# the rewards model,
	puts fmdp.rewards
	
	# and above all, the learned politic !
	puts fmdp.politic
	

## Copyright
Copyright (c) 2013 Vincent Renaudineau. See [LICENSE][] for details.

[license]: https://github.com/Timmy72/ruby-sdyna/blob/master/LICENSE.md
