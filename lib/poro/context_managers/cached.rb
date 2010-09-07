module Poro
  module ContextManagers
    # Identical to the base ContextManager except that it caches the contexts for
    # each class instead of re-fetching them each time.
    class Cached < ContextManager
      
      # Initialize the context manager with the given block.  See
      # ContextManager#initialize for more details.
      def initialize(&context_factory_block)
        super
        @context_cache = {}
      end
      
      # Fetches the context from the block the first time it is needed, and
      # caches it for all other returns.
      def fetch(klass)
        if( !@context_cache.has_key?(klass) )
          @context_cache[klass] = super(klass)
        end
        return @context_cache[klass]
      end
      
    end
  end
end