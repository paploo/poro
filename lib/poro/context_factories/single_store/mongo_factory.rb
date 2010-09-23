module Poro
  module ContextFactories
    module SingleStore
      # Creates a factory that generates MongoContext instances to the supplied
      # database, automatically setting the data_store to point at the collection
      # with the underscored, pluralized name of the class backing it.
      #
      # One can further configure the Context in several ways:
      # 1. Supply a block to new.
      # 2. Configure in the model.
      # 3. Fetch the Context directly, though this is considered bad form.
      # Wichever method you choose, it is wise to be consistent throughout the
      # application.
      #
      # This factory does not allow complex behaviors such as database switching.
      class MongoFactory < ContextFactory
        
        # Instantiates a new MongoContext.  The argument hash must include the
        # <tt>:connection</tt> key, and it must be a Mongo::Connection instance.
        def initialize(opts={})
          @connection = opts[:connection] || opts['connection']
          raise ArgumentError, "No mongo connection was supplied to #{self.class.name}." if @connection.nil?
          
          super() do |klass|
            collection_name = Util::Inflector.pluralize(Util::Inflector.underscore(klass.name.to_s)).gsub('/', '_')
            context = Contexts::MongoContext.new(klass)
            context.data_store = @connection[collection_name]
            yield(klass, context) if block_given?
            context
          end
        end
        
      end
    end
  end
end