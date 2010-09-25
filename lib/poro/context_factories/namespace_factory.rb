module Poro
  module ContextFactories
    # The NamespaceFactory uses the module namespace of the class to determine
    # which factory should be used to create a class instance.
    #
    # On initialization, the default factory should be set.  Until other
    # factories are registerd, all classes will recieve contexts created by
    # this factory.
    #
    # Other factories can be registered against various namespaces.  Namespaces
    # are given as a string and are evaluated from the bottom up.  For example,
    # if a factory is registered against the class Foo::Bar, then Foo::Bar and
    # Foo::Bar::Baz would each recieve contexts created via that factory, while
    # contexts registered against Foo::Zap would use the default context.
    class NamespaceFactory < ContextFactory
      
      # Initialize this namespace factory instance with the given default
      # factory.  Use <tt>register_factory</tt> to add more kinds of factories
      # to this app.
      #
      # If given a block, it is yielded self for further configuration.  This
      # departs slightly from the standard of yielding a Class or
      # Class and Context for configuration, but as this is more useful for
      # practicle applications.  (It also doesn't configure a context itself,
      # so giving separate blocks to the sub-factories given to it is more
      # appropriate.
      def initialize(default_factory)
        @root_node = CacheNode.new
        @root_node.factory = default_factory
        
        yield(self) if block_given?
        
        super() do |klass|
          factory = self.fetch_factory(klass)
          factory.nil? ? nil : factory.fetch(klass)
        end
      end
      
      # Registers a factory for a given namespace, given by a string.  If a
      # factory is already registered for this namespace, it overrides it.
      #
      # This registers the given factory not only for this namespace, but for
      # any sub-namespaces that haven't been specifically overriden.  Sub-namespace
      # overrides can be registered either before or after the namespace it overrides.
      def register_factory(factory, namespace='')
        namespace_stack = namespace.to_s.split('::')
        
        parse_block = lambda do |factory, namespace_stack, node|
          if( namespace_stack.length == 0 )
            node.factory = factory
          else
            name, *rest = namespace_stack
            child_node = node.children[name] || CacheNode.new
            node.children[name] = child_node
            parse_block.call(factory, rest, child_node)
          end
        end
        
        parse_block.call(factory, namespace_stack, @root_node)
        
        return factory
      end
      
      # Fetches the factory for a given namespace.
      #
      # This grabs the factory for the most specific matching namespace.
      def fetch_factory(namespace='')
        namespace_stack = namespace.to_s.split('::')
        
        lookup_block = lambda do |namespace_stack, last_seen_factory, node|
          last_seen_factory = node.factory || last_seen_factory
          if( namespace_stack.length == 0 )
            last_seen_factory
          elsif( !(node.children.include?(namespace_stack[0])) )
            last_seen_factory
          else
            name, *rest = namespace_stack
            lookup_block.call(rest, last_seen_factory, node.children[name])
          end
        end
        
        return lookup_block.call(namespace_stack, nil, @root_node)
      end
      
      # The internal class used to manage the namespace tree.  This should
      # never be used outside of this factory.
      #
      # This class stores the child notes for the namespace, as well as the
      # factory for this level in the namespace.
      class CacheNode
        
        # Initialize an empty node.
        def initialize
          @children = {}
          @factory = nil
        end
        
        # Returns the children--as a hash.  The keys are the module/class name,
        # and the values are the associated child node.
        #
        # This is the raw hash and can be manipulated directly.
        attr_reader :children
        
        # Returns the factory for this node, or nil if there is none.
        attr_reader :factory
        
        # Sets the factory for this node.
        attr_writer :factory
        
        def to_s
          return {:factory => factory, :children => children}.inspect
        end
        
      end
      
    end
  end
end