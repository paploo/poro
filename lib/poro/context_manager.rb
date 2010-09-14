module Poro
  # This class serves as both the base class for all context managers, and the
  # root class for retriving the application's context manager.
  class ContextManager
      
    # Returns the context manager instance for the application.
    # Returns nil if none is set.
    def self.instance
      raise RuntimeError, "No context manager configured for this application." if @instance.nil?
      return @instance
    end
    
    # Sets the context manager instance for the application.
    def self.instance=(instance)
      raise TypeError, "Cannot set an object of class #{instance.class} as the application's context manager." unless instance.kind_of?(self) || instance.nil?
      @instance = instance
    end
    
    # A shortcut method for building the application's context manager instance,
    # making it easier to get things up and running, but is not as flexible
    # as doing it yourself.
    #
    # The method creates a context manager for the application, and assigns the
    # given Context to all classes with default arguments.
    #
    # The primary argument is the context class to use by default.  This must
    # be either the fully qualified class, or the string name of the class within
    # the Poro::Contexts module.
    #
    # An optional second argument is the context manager class to use, and must
    # either be a fully qualified class, or the string name of the class within
    # the Poro::ContextManagers module.
    #
    # If you wish to override the default Context creation, an initialization
    # block may be passed.  This block is yielded the class for the Context
    # instance to manage, but also the default context class passed in.
    def self.build_application_instance(context_klass, context_manager_klass=Poro::ContextManagers::Cached)
      context_klass = Poro::Contexts.const_get(context_klass.to_s) unless context_klass.kind_of?(Class)
      context_manager_klass = Poro::ContextManagers.const_get(context_manager_klass.to_s) unless context_manager_klass.kind_of?(Class)
      
      self.instance = context_manager_klass.new do |klass|
        if(block_given?)
          yield(klass, context_klass)
        else
          context_klass.new(klass)
        end
      end
    end
    
    # Takes a factory block that delivers a configured context for the class
    # passed to it.
    def initialize(&context_factory_block)
      @context_factory_block = context_factory_block
    end
    
    # Fetches the context for a given class.
    #
    # This is a basic implementation that calls the factory block each and
    # every time.  Usually, one uses a subclass that caches the values, but
    # in some instaces it is necessary to have more complex behavior.
    #
    # Subclasses are expected to call this method instead of running the block
    # directly.
    def fetch(klass)
      begin
        return @context_factory_block.call(klass)
      rescue Exception => e
        raise RuntimeError, "Error encountered during context manager fetch: #{e.class}: #{e.message.inspect}", e.backtrace
      end
    end
  
  end
end