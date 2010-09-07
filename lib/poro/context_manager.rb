module Poro
  class ContextManager
      
      # Returns the context manager instance for the application.
    # Returns nil if none is set.
    def self.instance
      return @instance
    end
    
    # Sets the context manager instance for the application.
    def self.instance=(instance)
      @instance = instance
    end
    
    # Takes a factory block that delivers a configured context for the class
    # passed to it.
    def initialize(&context_factory_block)
      @context_factory_block = context_factory_block
    end
    
    # Fetches the context for a given class.
    #
    # This is a basic implementation that calls the factory block each time.
    # Subclasses with better behavior should be used instead.
    def fetch(klass)
      begin
        return @context_factory_block.call(klass)
      rescue Exception => e
        raise RuntimeError, "Error encountered during context manager fetch: #{e.class}: #{e.message.inspect}", e.backtrace
      end
    end
  
  end
end