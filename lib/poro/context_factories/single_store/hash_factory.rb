module Poro
  module ContextFactories
    module SingleStore
      # Creates a factory that generates a HashContext for each class.
      class HashFactory < ContextFactory
        
        # Initializes a new HashContext for each class.
        def initialize(opts={})
          super() do |klass|
            context = Contexts::HashContext.new(klass)
            yield(klass, context) if block_given?
            context
          end
        end
        
      end
    end
  end
end