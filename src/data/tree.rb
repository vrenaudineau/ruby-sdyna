# encoding: utf-8

require_relative "./variable"
require_relative "./example"
require_relative "./potential"
require_relative "./examples2"

module SDYNA
	# The base Node class.
	# A Node has a parent, a content, and eventually children attach by labeled branches.
	# Content and branches may be any kind of objects, but branches must have hash and eql? methods defined.
	# Each branch has a uniq label for this node. The branch of the same node cannot have same label.
	class Node
		# Construct recursively the whole tree describes in \a tree.
		# tree := subtree
		# subtree := {nodeContent=>{branchLabel=>subtree}} | leafContent
		# leafContent := anything_except_hash | {:leaf=>nodeContent}
		def Node.from_hash(tree)
			node = self.new
			# Si on est sur une feuille classique
			if ! tree.kind_of?(Hash)
				node.content = tree
			elsif tree.key?(:leaf)
				node.content = tree[:leaf]
			else
				content, subTrees = tree.first
				node.content = content
				for branchValue, subtree in subTrees
					child = self.from_hash(subtree)
					node[branchValue] = child
				end
			end
			return node
		end
		
		include Enumerable
		attr_accessor :parent, :content
		def initialize(content=nil, parent=nil)
			@parent = parent
			@branches = {}
			@content = content
		end
		# Equality on nodes' content, branches and subtree only. Doesn't compare parents.
		def ==(o)
			return false unless o.kind_of?(Node)
			return false unless @content == o.content
			return false unless @branches.keys.size == o.branches.size
			return o.all? { |branch,child|
				@branches.key?(branch) && child == @branches[branch]
			}
		end
		# Return the child attach on the \a branch, or nil.
		# If \a branch is a Node, return the corresponding branch.
		# An ArgumentError in raised if \a branch is neither a branch nor a child.
		def [](branch)
			return @branches[branch] if @branches.key?(branch)
			return @branches.key(branch) if @branches.value?(branch)
			raise ArgumentError, "#{branch.inspect} is neither a branch nor a child." 
		end
		# Assign the \a child to the \a branch.
		# If a child already exist on this branch, set it as a root node.
		# If \a child is already a child, delete the previous branch.
		# Node become the new parent of \a child.
		# Return \a child.
		def []=(branch, child)
			raise ArgumentError, "Wait a Node as second argument, got a #{child.class}" unless child.kind_of?(Node)
			@branches[branch].set_as_root! if ! @branches[branch].nil?
			@branches.delete(@branches.key(child)) if @branches.value?(child)
			@branches[branch] = child
			child.parent = self
			return child
		end
		# Return an Array of branches values.
		def branches
			return @branches.keys
		end
		# Return an Array of children.
		def children
			return @branches.values
		end
		# Return a copy of this node as a root node.
		def clone
			c = self.class.new
			c.init_copy(self)
			return c
		end
		# Set all children to root nodes and clear branches.
		def detach_children!
			@branches.each do |_,child| child.set_as_root! end
			@branches.clear
		end
		# Iterate over (branch, child) pairs.
		# Return self.
		def each
			@branches.each do |branch,child|
				yield(branch,child)
			end
			return self
		end
		#
		def empty?
			return leaf? && content.nil?
		end
		# Object are equal if they are the same object (ie same object_id).
		# This method is usefull for hashes.
		def eql?(o)
			return self.object_id == o.object_id
		end
		# Copy content and branches of \a o but not its parent.
		def init_copy(o)
			@content = o.content
			detach_children!
			o.each do |branch,child|
				@branches[branch] = self.class.new.init_copy(child)
				@branches[branch].parent = self
			end
			return self
		end
		# Return true if this node has no child.
		def leaf?
			return @branches.empty?
		end
		# Assign as a leaf : set content to \a value and clear branches.
		def leaf=(value)
			detach_children!
			@content = value
		end
		# Return all leafs.
		def leafs
			return [self] if self.leaf?
			return children.collect { |child| child.leafs }.flatten
		end
		# Replace this node by \a other, ie copy content and assign \a other's
		# children to self. Return self
		def replace!(other)
			@content = other.content
			detach_children!
			other.each do |branch,child|
				@branches[branch] = child
				child.parent = self
			end
			return self
		end
		# Return true if this node is a root node, ie it has no parent.
		def root?
			return @parent.nil?
		end
		# Set parent to nil. Return self.
		def set_as_root!
			@parent = nil
			return self
		end
		# Return the number of node is the subtree.
		# x -true> 3
		#	-false> 4
		# is a 3 nodes tree.
		def size
			return 1+(children.inject(0) { |s,c| s+c.size})
		end
		def to_s(previousTab = 0, current = 0)
			return "[empty node]" if empty?
			s = ""
			if self.leaf?
				if @content.kind_of?(Numeric)
					s += "%.5s" % @content 
				else
					s += "%s" % @content.inspect
				end
			else
				s += "%s=>" % @content.inspect
				myTab = current+s.length
				for b, subtree in @branches
					temp = b.to_s + " : "
					s += temp
					s += subtree.to_s( myTab, myTab+temp.length )
				end
				s.strip!
			end
			s += "\n" + " "*previousTab if previousTab > 0
			return s
		end	# Node.to_s
	end # class Node
	Tree = Node
	
	# Must be a subclass of Node and require a mix method.
	# Allow to combine trees, by appending a tree to each leaf of an other,
	# or by merging multiple of them.
	module Combinable
		# Append the \a subtree to each leaf of this node.
		# Mix the leaf value with each \a subtree leaf.
		# If \a simplify is true (by default) and if a simplify! method is define,
		# simplify the tree before return it.
		def append!(subtree,simplify=true)
			if self.leaf?
				if ! subtree.empty?
					value = @content
					init_copy(subtree)
					for l in leafs()
						l.mix(value)
					end
				end
			else
				for l in self.leafs
					l.append!(subtree,false)
				end
			end
			self.simplify! if simplify && self.respond_to?(:simplify!)
			return self
		end # def append
		
		# \a others an Array of trees.
		# Warning the Array is empty at the end,
		# and trees in others are modified if \a canModifyTrees is true (default).
		def merge!(others, canModifyTrees=true)
			if others.empty?
				return self
			else
				t = others.shift
				t = t.clone unless canModifyTrees
				return self.append!(t.merge!(others, canModifyTrees))
			end
		end # def merge
		
		module ClassMethods
			# \a list an Array of trees.
			# Warning the Array is empty at the end,
			# and trees in others are modified if \a canModifyTrees is true (default).
			def merge(list,canModifyTrees=true)
				if list.empty?
					return self.new
				elsif canModifyTrees
					return list.shift.merge!(list, canModifyTrees)
				else
					return list.shift.clone.merge!(list, canModifyTrees)
				end
			end
		end
		
		def self.included(base)
			base.extend(ClassMethods)
		end
	end # module Combinable
	
	# The base Node with tests on internal nodes and values on leafs.
	# The content is a test which determines branches values.
	# The test must be iterable.
	class TestNode < Node
		include Combinable
		
		# \a path can by a branch or a Hash of test/branch value.
		# If this is a Hash, go down the subtree until it cannot,
		# and return the node.
		def [](path)
			if self.leaf?
				return self
			elsif ! path.kind_of?(Hash)
				return super(path)
			elsif path.key?(@content)
				return @branches[path[@content]][path]
			else
				return self
			end
		end
		
		# Default mix : += value
		def mix(value)
			raise "Can only mix in a leaf node." if ! self.leaf?
			@content += value
		end
		
		# Return a Hash[test=>value]. Keys orders is from the node parent
		# to the root.
		def path
			path = {}
			current = self
			while ! current.parent.nil?
				previous = current
				current = current.parent
				path[current.content] = current[previous]
			end
			return path
		end
		# Remove unnecessary branches (equal branches and bad branch value
		# if test has already been assigned) and simplify children.
		# Return self.
		def simplify!(context = {})
			raise ArgumentError, "Wait a Hash, got a #{context.class}" if ! context.kind_of?(Hash)
			
			return self if self.leaf?
			
			# If the variable that is tested has already been tested,
			# just replace with the good branch.
			if context.key?(@content)
				correctNode = self[context[@content]]
				replace!(correctNode)
				return simplify!(context)
			end
			
			# On simplifie chaque branche
			for branch, subtree in @branches
				newContext = context.clone
				newContext[@content] = branch
				subtree.simplify!(newContext)
			end
			
			# Si les branches sont égales, on remplace
			if children.all? { |c| c == children.first }
				correctNode = children.first
				replace!(correctNode)
			end
			
			return self
		end	# Node.simplify!
		# Without argument, return true if the node is an internal node, ie has children.
		# With a Variable as argument, return true if this node tests this Variable.
		def test?(var = nil)
			if var.nil?
				return ! @branches.empty?
			else
				return @content == var
			end
		end
		# Set as a test node. \a var must be an Enumerable.
		# If the node were already testing a var, detach each child.
		# Return var.
		def test=(var)
			detach_children! if test?
			@content = var
			var.each do |vi|
				@branches[vi] = self.class.new(nil,self)
			end
			return var
		end
		def test
			return @content
		end
	end # class TestNode
	TestTree = TestNode
	
	#
	class TransitionNode < TestNode
		attr_accessor :examples, :checkCpt
		
		def initialize(content=nil, parent=nil)
			if content.kind_of?(Variable)
				super(Potential.new(content), parent)
			else
				super
			end
			# list of example that match this node
			@examples = Examples.new
			# check counter is used to know if we must recheck the node in update_tree_s.
			@checkCpt = 1
		end
		
		def init_copy(o)
			super(o)
			if o.kind_of?(TransitionNode)
				@examples = o.examples.dup
				@checkCpt = o.checkCpt
			end
			return self
		end
		
		def mix(value)
			raise "Can only mix in a leaf node." if ! self.leaf?
			@content *= value
		end
		
		def to_s(previousTab = 0, current = 0)
			e = "[#{examples.size}]"
			return e+super(previousTab, current+e.size)
		end
	end
	TransitionTree = TransitionNode
	
	#
	class RewardNode < TestNode
		attr_accessor :examples
		
		def initialize(content=nil, parent=nil)
			super
			# list of example that match this node
			@examples = Examples.new
		end
		
		def to_s(previousTab = 0, current = 0)
			e = "[#{examples.size}]"
			return e+super(previousTab, current+e.size)
		end
		
		def clone
			n = super
			n.examples = @examples.dup
			return n
		end
	end
	RewardTree = RewardNode
	
	#
	class ValueNode < TestNode
		attr_accessor :sigma
		
		def initialize(content=nil, parent=nil)
			super
			@sigma = 0.1
		end
		
		def init_copy(o)
			super(o)
			@sigma = o.sigma if o.kind_of?(ValueNode)
			return self
		end
		
		def mix(value)
			raise "Can only mix in a leaf node." if ! self.leaf?
			@content = [@content,value].max
		end
		
		def simplify!(context = {})
			super(context)
			
			if ! leaf? && children.all? { |c| c.leaf? }
				min, max = children.collect { |c| c.content }.minmax
				self.leaf = (max + min) / 2.0 if max - min < @sigma
			end
		end
	end
	ValueTree = ValueNode
	
	#
	class PoliticNode < TestNode
		
	end
	PoliticTree = PoliticNode
end # module SDYNA
