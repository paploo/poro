module Poro
  module ContextFactories
    # The namespace for all the factories that only allow your application to
    # back a single store.
    #
    # If your application needs to create multiple stores, or initiate complex
    # behavior, it is better to either create your own factory, or supply a
    # block to the default factory.
    # It is also possible to manually instantiate these factories to delegate to
    # them if you wish to use their functionality in your own.  It is usually
    # best to cache your single instance, instead of making new ones for each use.
    module SingleStore
      
      # A shortcut method to instantiate the
      # individual single-context factories in this module.
      #
      # This transforms the given name into the appropriate factory, and passes the
      # options hash directly to the created factory.
      #
      # If a block is supplied, it will be passed the class that a Context was
      # generated for, and the Context itself.
      def self.instantiate(name, opts={}, &block)
        underscored_name = Util::Inflector.underscore(name.to_s)
        klass_name = Util::Inflector.camelize( underscored_name.gsub(/_(context|factory)$/, '') + '_factory' )
        klass = Util::ModuleFinder.find(klass_name, self, true)
        return klass.new(opts, &block)
      end
    
    end
  end
end

require 'poro/context_factories/single_store/hash_factory'
require 'poro/context_factories/single_store/mongo_factory'