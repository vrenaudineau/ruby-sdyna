# encoding: utf-8
require_relative "variable"
require_relative "instanciation"
require_relative "potential"

module SDYNA
	#
	class Node
		#
		class PathIterator
			include Enumerable
			def initialize( tree )
				@tree, @current, @open = tree, tree, tree.children.reverse
			end
			def next
				return [] if @open.empty?
				begin
					@current = @open.pop
					@open += @current.children.reverse
				end while ! @current.leaf?
				return @current.path
			end			
			def next?
				return ! @open.empty?
			end
			def each
				@current, @open = @tree, @tree.children.reverse
				yield self.next while next?
				return self
			end
		end # class PathIterator
		
		# Pour l'initialisation manuelle, description de l'arbre sous la forme :
		# tree := {variable=>{valeur=>tree}} | content
		# variable := string | Variable
		# valeur := anything
		# content := anything_except_hash | {:leaf=>potential}
		# potential := {variable=>{valeur=>Float}}
		def Node.from_hash(h)
			node = Node.new
			# Si on est sur une feuille classique
			if ! h.kind_of?(Hash)
				node.set_leaf(h)
			# Si on est sur une feuille potentiel
			elsif h.key?(:pot)
				content = h[:pot]
				node.set_leaf(Potential.from_hash(content))
			# Si on a un noeud test
			else
				raise ArgumentError, "A node can test only one variable. Here test #{h.keys}" if h.size != 1
				var, subTrees = h.first
				var = Variable.new(var, subTrees.keys) if var.kind_of?(String)
				node.set_test(var)
				for vi, subtree in subTrees
					child = Node.from_hash(subtree)
					node[vi] = child
				end
			end
			return node
		end	# Node.from_hash
		
		attr_reader :test
		attr_accessor :parent, :content, :exemples
		#
		def initialize(parent = nil)
			# Parent du noeud. Peut être nil si ce noeud est la racine.
			@parent = parent
			# Variable ou nil si  c'est une feuille
			@test = nil
			# {valeur de la variable=>Node}
			@branches = {}
			# Potential pour @transition, Numeric pour @récompense et @valeur
			@content = nil
			# list of exemple that match this node
			@exemples = []
		end # Node.initialize
		# [](b : U) : Node
		# [](n : Node) : U
		# [](i : Instanciation or Hash) : Node
		def [](arg)
			if arg.kind_of?(Instanciation) || arg.kind_of?(Hash)
				#~ arg = Instanciation.from_hash(arg) if arg.kind_of?(Hash)
				#~ raise ArgumentError, "Instanciation doesn't test the Variable #{@test.label}." if ! arg.has_var?(@test)
				return self if ! arg.key?(@test)
				return @branches[arg[@test]][arg]
			elsif arg.kind_of?(Node)
				raise ArgumentError, "#{arg} is not a child of this node" if ! @branches.value?(arg)
				return @branches.key(arg)
			else
				raise ArgumentError, "The argument (#{arg}) is not a branch of this node : (#{@branches.keys})" if @branches[arg].nil?
				return @branches[arg]
			end
		end	# Node.[]
		# node[child] = newChild
		# node[branch] = newChild
		# detach child, and attach newChildren.
		def []=(b, n)
			raise ArgumentError, "Wait a Node as second argument, got a #{n.class}" unless n.kind_of?(Node)
			if b.kind_of?(Node)
				b = @branches.key(b)
				raise ArgumentError, "The first argument is not a child of that Node." if b.nil?
			end
			# Détache l'ancien enfant
			if ! @branches[b].nil?
				@branches[b].set_as_root!
			end
			# Attache le nouveau
			@branches[b] = n
			n.parent = self
			return n
		end	# Node.[]=
		# o is an other node. Don't test parent.
		# Order of branches either.
		def ==(o)
			return false unless o.kind_of?(Node) && @test == o.test && @content == o.content
			return @branches.all? do |branch,child|
				! o[branch].nil? && child == o[branch]
			end
		end	# Node.==
		def eql?(o)
			return self.object_id == o.object_id
		end
		# t un arbre, f la fonction de combinaison
		def append!( t, fct )
			raise ArgumentError, "t must be a Tree (with a root node) !" unless t.kind_of?( Tree )
			if self.leaf?
				if ! t.empty?
					for l in t.leafs
						l.content = fct[ @content, l.content ] # TODO
					end
					self.replace!(t)
				end
			else
				for l in self.leafs
					l.append!( t.clone, fct )
				end
			end
			return self.simplify!
		end	# Node.append!
		#
		def branches
			return @branches.keys
		end	# Node.branches
		#
		def branchesAndChildren
			return @branches.dup
		end	# Node.branchesAndChildren
		#
		def child?( o )
			return @branches.value?(o)
		end	# Node.child
		#
		def children
			return @branches.values
		end	# Node.children
		#
		def children?
			return ! @branches.empty?
		end	# Node.children?
		# Clone un Node sauf son parent (il est root), et sa descendance
		def clone
			n = Node.new()
			n.parent = nil
			n.set_test( @test ) unless @test.nil?
			n.exemples = @exemples.dup
			@branches.each do |branch,node|
				n[branch] = node.clone
				n[branch].parent = n
			end
			n.content = @content
			return n
		end	# Node.clone
		#
		def content_for(i)
			return @content if self.leaf?
			raise ArgumentError, "state is not complete : #{@test} is missing." unless i.key?(@test)
			return self[i[@test]].content_for(i)
		end	# Node.content_for
		# do a copy of that node, without parent.
		def dup
			n = super
			n.parent = nil
		end	# Node.dup
		#
		def empty?
			return @branches.empty? && @content.nil?
		end	# Node.empty?
		#
		def iterator
			return PathIterator.new(self)
		end	# Node.iterator
		# 
		def leaf?
			return @branches.empty?
		end	# Node.leaf?
		#
		def leafs
			return [self] if self.leaf?
			list = []
			@branches.each do |branch,child|
				list += child.leafs
			end
			return list.flatten
		end	# Node.leafs
		#
		def path
			path = []
			current = self
			while ! current.parent.nil?
				previous = current
				current = current.parent
				path.unshift( [current.test,current[previous]] )
				#~ puts path.inspect
			end
			#~ puts "#{path.inspect} => #{Hash[path]}"
			return Hash[path]
		end	# Node.path
		#
		def remove!(child)
			raise ArgumentError, "Wait a Node, got a #{child.class}" unless child.kind_of?(Node)
			@branches.delete(@branches.key(child))
			child.set_as_root!
			return child
		end	# Node.remove!
		# Replace this node with n. Copy test, content, and children.
		# Attache new children to this node. Detache previous.
		# return self
		def replace!(n)
			raise ArgumentError, "can't replace by self !!" if n.object_id == self.object_id
			# On détache les enfants
			@branches.values.each do |child|
				child.set_as_root!
			end
			# On copie tout sauf le parent
			@content = n.content
			@test = n.test
			#~ @branches = n.branchesAndChildren
			# On ratache les enfants à nous
			#~ @branches.values do |child|
				#~ child.parent = self
			#~ end
			@branches.clear
			n.branchesAndChildren.each do |branch, child|
				@branches[branch] = child
				child.parent = self
			end
			@exemples = n.exemples.dup
			# Au cas où
			#~ n.set_as_root!
			return self
		end	# Node.replace!
		#
		def root?
			return @parent.nil?
		end # Node.root?
		#
		def set_as_root!
			@parent = nil
			self
		end	# Node.set_as_root!
		# context is the previous context == {variable=>value} tested
		# return the new sub-tree simplified
		def simplify!( context = {} )
			raise ArgumentError, "Wait a Hash, got a #{context.class}" if ! context.kind_of?( Hash )
			
			return self if self.leaf?
			
			# If the variable that is tested has already been tested,
			# just replace with the good branch.
			if context.key?( @test )
				correctNode = self[context[@test]]
				replace!(correctNode)
				return simplify!(context)
			end
			
			# On simplifie chaque branche
			for branchValue, subtree in @branches
				newContext = context.clone
				newContext[@test] = branchValue
				subtree.simplify!(newContext)
			end
			
			# TODO : faire pour @branches.keys.size > 2
			if children.size == 2 && children.first == children.last
				correctNode = children.first
				replace!(correctNode)
			end
			
			return self
		end	# Node.simplify!
		#
		def set_leaf(content)
			@branches.clear
			@test = nil
			@content = content
			return self
		end	# Node.set_leaf
		#
		def set_test(test)
			raise ArgumentError, "Wait a Variable, got a #{test.class}" unless test.kind_of?(Variable)
			@content = nil
			@test = test
			@branches.values.each do |child|
				child.set_as_root!
			end
			@branches = {}
			for vi in test.values
				@branches[vi] = Node.new(self)
			end
			return self
		end	# Node.set_test
		# 
		def test?( v )
			return @test == v
		end	# Node.test?
		#
		def to_s( previousTab = 0, current = 0 )
			return "[empty node]" if empty?
			s = "[#{@exemples.size}]"
			#~ s = "[#{object_id}]"
			if self.leaf?
				if @content.kind_of?(Numeric)
					s += "%.5s" % @content 
				else @content.kind_of?(Potential)
					s += @content.to_s
				end
			else
				s += @test.label + "=>"
				myTab = current+s.length
				#~ puts "#{@test} => #{@branches.keys}"
				for vi, subtree in @branches
					#~ puts "WOUAIHHHHH !!!!"
					temp = vi.to_s + " : "
					s += temp
					s += subtree.to_s( myTab, myTab+temp.length )
				end
				s.strip!
			end
			s += "\n" + " "*previousTab if previousTab > 0
			#~ puts "#{@test} =>\n#{s}"
			return s
		end	# Node.to_s
		#
		def to_s2( n = 0 )
			return "[empty node]" if empty?
			if self.leaf?
				return @content.to_s
			else
				s = @test.to_s + "\n"
				for vi, subtree in @branches
					s += "\t"*n
					s += vi.to_s + " : "
					s += subtree.to_s( n+1 )
					s += "\n"
				end
				return s.chop
			end
		end	# Node.to_s2
	end # class Node
	
	#
	class Tree < Node
		def Tree.from_hash(h)
			tree = Tree.new
			tree.replace!( Node.from_hash(h) )
			return tree
		end # Tree.from_hash
		# others un tableau d'arbre, f la fonction de combinaison
		# return a Tree
		def Tree.merge( others, f )
			if others.empty?
				return Tree.new()
			elsif others.size == 1
				return others[0].clone;
			else
				return others.pop.clone.append!( Tree.merge( others, f ), f ).simplify!;
			end
		end # Tree.merge
		# Empêche d'avoir un argument
		def initialize
			super
		end # Tree.initialize
		#
		def to_s
			return "[empty tree]" if empty?
			return super
		end # Tree.to_s
		#
		def clone
			n = super
			t = Tree.new
			t.replace!(n)
			return t
		end # Tree.clone
	end # class Tree
end
