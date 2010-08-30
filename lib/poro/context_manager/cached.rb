module Poro
  # Identical to the base ContextManager except that it caches the contexts for
  # each class instead of re-fetching them.
  module ContextManager
    class Cached < Base
  
      def initialize(&context_factory_block)
        super
        @context_cache = {}
      end
  
      def fetch(klass)
        if( !@context_cache.has_key?(klass) )
          @context_cache[klass] = super(klass)
        end
        return @context_cache[klass]
      end
  
    end
  end
end