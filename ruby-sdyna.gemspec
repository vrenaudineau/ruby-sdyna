Gem::Specification.new do |s|
  s.name        = 'ruby-sdyna'
  s.version     = '1.0.0'
  s.date        = '2013-01-18'
  s.summary     = "Reinforcment Learning Algorithm SDYNA."
  s.description = "The library allow to do reinforcment learning in factorized Markov process with SDYNA algorithm."
  s.authors     = ["Vincent Renaudineau"]
  s.email       = ["6mszahi9@randomail.net"]
  s.homepage    = "https://github.com/Timmy72/ruby-sdyna"
  s.files       = ["src/sdyna.rb",
				   "src/planning.rb",
				   "src/acting.rb",
				   "src/learning.rb",
				   "src/data/variable.rb",
				   "src/data/potential.rb",
				   "src/data/example.rb",
				   "src/data/examples2.rb",
				   "src/data/tree.rb",
				   "src/data/fmdp.rb",
				   "src/learning/buildtree.rb",
				   "src/learning/buildtrees.rb",
				   "src/learning/buildtreef.rb",
				   "src/learning/updatetree.rb",
				   "src/learning/updatetrees.rb"]
end

