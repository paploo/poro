module Poro
  # This class serves as both the base class for all context factories, and the
  # root class for retriving the application's context factory.
  class ContextFactory
    
    # The base error type for a factory specific error.
    class FactoryError < RuntimeError; end
      
    # Returns the context factory instance for the application.
    # Returns nil if none is set.
    #
    # One normally gets this via Context.factory, but it doesn't make a difference.
    def self.instance
      raise RuntimeError, "No context factory configured for this application." if @instance.nil?
      return @instance
    end
    
    # Sets the context factory instance for the application.
    #
    # One normally sets this via Context.factory, but it doesn't make a difference.
    def self.instance=(instance)
      raise TypeError, "Cannot set an object of class #{instance.class} as the application's context factory." unless instance.kind_of?(self) || instance.nil?
      @instance = instance
    end
    
    # Takes a factory block that delivers a configured context for the class
    # passed to it.
    def initialize(&context_factory_block)
      @context_factory_block = context_factory_block
      @context_cache = {}
    end
    
    def context_managed_class?(klass)
      return klass && klass.include?(Poro::Persistify)
    end
    
    # Fetches the context for a given class, or returns nil if the given object
    # should not have a context.
    #
    # This is the most basic implementation possible, though, like any context
    # factory must do, it guarantees that the same Context instance will be
    # returned for the same class throughout the lifetime of the application so
    # that configuration subsequent to generation is honored.
    #
    # Subclasses are expected to call this method instead of running the factory
    # block directly.
    def fetch(klass)
      raise FactoryError, "Cannot create a context for class #{klass.inspect}, as it has not been flagged for persistence.  Include Context::Persistify to fix." unless self.context_managed_class?(klass)
      if( !@context_cache.has_key?(klass) )
        @context_cache[klass] = build(klass)
      end
      return @context_cache[klass]
    end
    
    private
    
    # Calls the context factory block to generate a new context.  This should
    # not be called directly, but instead left to the fetch method to call when
    # needed so that it is only called once per class during the application's
    # lifetime.
    def build(klass)
      begin
        return @context_factory_block.call(klass)
      rescue Exception => e
        raise RuntimeError, "Error encountered during context fetch build: #{e.class}: #{e.message.inspect}", e.backtrace
      end
    end
    
  end
end