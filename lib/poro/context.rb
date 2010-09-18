module Poro
  # This is the abstract superclass of all Contexts.
  #
  # The Context is the responsible delegate for directly interfacing with the
  # persistence layer.  Each program class that needs persistence must have its
  # own context instance that knows how to store/retrive only instances of that
  # class.
  #
  # All instances respond to the methods declared here, and must conform to
  # the rules described with each method.
  #
  # One normally uses a subclass of Context, and that subclass may have extra
  # methods for setting options and configuring behavior.
  class Context
    
    # This error is thrown when a save fails.
    class SaveError < RuntimeError; end
    
    # This error is thrown when a remove fails.
    class RemoveError < RuntimeError; end
    
    # Fetches the context for the given object or class from
    # <tt>ContextFactory.instance</tt>.
    # Returns nil if no context is found.
    def self.fetch(obj)
      if( obj.kind_of?(Class) )
        return self.factory.fetch(obj)
      else
        return self.factory.fetch(obj.class)
      end
    end
    
    # Returns true if the given class is configured to be represented by a
    # context.  This is done by including Poro::Persistify into the module.
    def self.managed_class?(klass)
      return self.factory.context_managed_class?(klass)
    end
    
    # A convenience method for further configuration of a context over what the
    # factory does, via the passed block.
    #
    # This really just fetches (and creates, if necessary) the
    # Context for the class, and then yields it to the block.  Returns the context.
    def self.configure_for_klass(klass)
      context = self.fetch(klass)
      yield(context) if block_given?
      return context
    end
    
    # Returns the application's ContextFactory instance.
    def self.factory
      return ContextFactory.instance
    end
    
    # Sets the application's ContextFactory instance.
    def self.factory=(context_factory)
      ContextFactory.instance = context_factory
    end
    
    # Initizialize this context for the given class.  Yields self if a block
    # is given, so that instances can be easily configured at instantiation.
    #
    # Subclasses are expected to use this method (through calls to super).
    def initialize(klass)
      @klass = klass
      self.data_store = nil unless defined?(@data_store)
      self.primary_key = :id
      yield(self) if block_given?
    end
    
    # The class that this context instance services.
    attr_reader :klass
    
    # The raw data store backing this context.  This is useful for advanced
    # usage, such as special queries.  Be aware that whenever you use this,
    # there is tight coupling with the underlying persistence store!
    attr_reader :data_store
    
    # Sets the raw data store backing this context.  Useful during initial
    # configuration and advanced usage, but can be dangerous.
    attr_writer :data_store
    
    # Returns the a symbol for the method that returns the Context assigned
    # primary key for the managed object.  This defaults to <tt>:id</tt>
    attr_reader :primary_key
    
    # Set the method that returns the Context assigned primary key for the
    # managed object.
    #
    # Note that if you want the primary key's instance variable value to be
    # purged from saved data, you must name the accessor the same as the instance
    # method (like if using attr_reader and attr_writer).
    def primary_key=(pk)
      @primary_key = pk.to_sym
    end
    
    # Returns the primary key value from the given object, using the primary
    # key set for this context.
    def primary_key_value(obj)
      return obj.send( primary_key() )
    end
    
    # Sets the primary key value on the managed object, using the primary
    # key set for this context.
    def set_primary_key_value(obj, id)
      method = (primary_key().to_s + '=').to_sym
      obj.send(method, id)
    end
    
    # Fetches the object from the store with the given id, or returns nil
    # if there are none matching.
    def fetch(id)
      return nil
    end
    
    # Saves the given object to the persistent store using this context.
    #
    # Subclasses do not need to call super, but should follow the given rules:
    #
    # Returns self so that calls may be daisy chained.
    #
    # If the object has never been saved, it should be inserted and given
    # an id.  If the object has been added before, the id is used to update
    # the existing record.
    #
    # Raises a SaveError if save fails.
    def save(obj)
      obj.id = obj.object_id if obj.respond_to?(:id) && obj.id.nil? && obj.respond_to?(:id=)
      return obj
    end
    
    # Remove the given object from the persisten store using this context.
    #
    # Subclasses do not need to call super, but should follow the given rules:
    #
    # Returns self so that calls may be daisy chained.
    #
    # If the object is successfully removed, the id is set to nil.
    #
    # Raises a RemoveError is the remove fails.
    def remove(obj)
      obj.id = nil if obj.respond_to?(:id=)
      return obj
    end
    
    # Convert the data from the data store into the correct plain ol' ruby
    # object for the class this context represents.
    #
    # For non-embedded persistent stores, only records of the type for this
    # context must be handled.  However, for embedded stores--or more
    # complex embedded handling on non-embedded stores--more compex
    # rules may be necessary, handling all sorts of data types.
    #
    # The second argument is reserved for state information that the method
    # may need to pass around, say if it is recursively converting elements.
    # Any root object returned from a "find" in the data store needs to be
    # able to be converted
    def convert_to_plain_object(data, state_info={})
      return data
    end
    
    # Convert a plain ol' ruby object into the data store data format this
    # context represents.
    #
    # For non-embedded persistent stores, only records of the type for this
    # context must be handled.  However, for embedded stores--or more
    # complex embedded handling on non-embedded stores--more compex
    # rules may be necessary, handling all sorts of data types.
    #
    # The second argument is reserved for state information that the method
    # may need to pass around, say if it is recursively converting elements.
    # Any root object returned from a "find" in the data store needs to be
    # able to be converted
    def convert_to_data(obj, state_info={})
      return obj
    end
    
  end
end




module Poro
  class Context
    # A mixin that contains all the context find methods.
    #
    # Note that <tt>fetch</tt> is considered basic functionality and not a 
    # find method, even though it technically finds by id.
    module FinderMethods
      
      # Fetches records according to the parameters given in opts.
      #
      # Contexts attempt to implement this method as uniformily as possible,
      # however some features only exist in some backings and may or may not be
      # portable.
      #
      # WARNING: For performance, some Contexts may not check that the passed
      # options are syntactically correct before passing off to their data store.
      # This could result in the inadvertent support of some underlying functionality
      # that may go away in a refactor.  Please make sure you only use this method
      # in the way it is documented for maximal future compatibility.
      #
      # Note that if you wish to work more directly with the data store's find
      # methods, one should see <ttdata_store_find_all</tt> and
      # <tt>data_store_find_first</tt>.
      #
      # The first argument must be one of the following:
      # * An ID
      # * An array of IDs
      # * :all or :many
      # * :first or :one
      #
      # The options are as follows:
      # [:conditions] A hash of key-value pairs that will be matched against.  They
      #               are joined by an "and".  Note that in contexts that support embedded
      #               contexts, the keys may be dot separated keypaths.
      # [:order]      The name of the key to order by in ascending order, an array of
      #               keys to order by in ascending order, an array of arrays, or a hash, where
      #               the first value is the key, and the second value is either :asc or :desc.
      # [:limit]      Either the limit of the number of records to get, an array of the
      #               limit and offset, or a hash with keys :limit and/or :offset.
      #
      # Subclasses rarely need to override this method, as it distributes its call
      # to one of the helper find methods.
      def find(arg, opts={})
        if(arg == :all || arg == :many)
          return find_all(opts)
        elsif( args == :first || arg == :one)
          return find_first(opts)
        elsif( arg.respond_to?(:map) )
          return arg.map {|id| fetch(id)}
        else
          return fetch(id)
        end
      end

      # Returns an array of all the records that match the following options.
      # See <tt>find</tt> for more help.
      def find_all(opts)
        return []
      end

      # An alias for find_all.
      def find_many(opts)
        return find_all(opts)
      end

      # Returns the first record that matches the following options.
      # See <tt>find</tt> for more help.
      def find_first(opts)
        hashize_limit(opts[:limit])[:limit] = 1
        return find_all(opts)
      end

      # An alias for first.
      def find_one(opts)
        return find_first(opts)
      end

      # Calls the relevant finder method on the underlying data store, and
      # converts all the results to plain objects.
      #
      # Use of this method is discouraged as being non-portable, but sometimes
      # there is no alternative but to get right down to the underlying data
      # store.
      #
      # Note that if this method still isn't enough, you'll have to use the
      # data store and convert the objects yourself, like so:
      #   SomeContext.data_store.find_method(arguments).map {{|data| SomeContext.convert_to_plain_object(data)}
      def data_store_find_all(*args, &block)
        return [].map {|data| convert_to_plain_object(data)}
      end
      alias_method :data_store_find_many, :data_store_find_all

      # Calls the relevant finder method on the underlying data store, and
      # converts the result to a plain object.
      #
      # Use of this method is discouraged as being non-portable, but sometimes
      # there is no alternative but to get right down to the underlying data
      # store.
      #
      # Note that if this method still isn't enough, you'll have to use the
      # data store and convert the object yourself, like so:
      #   SomeContext.convert_to_plain_object( SomeContext.data_store.find_method(arguments) )
      def data_store_find_first(*args, &block)
        return convert_to_plain_object(nil)
      end
      alias_method :data_store_find_one, :data_store_find_many
      
      private

      # Cleans the find opts.
      def clean_find_opts(opts)
        cleaned_opts = opts.dup
        cleaned_opts[:limit] = hashize_limit(opts[:limit]) if opts.has_key?(:limit)
        cleaned_opts[:order] = hashize_order(opts[:order]) if opts.has_key?(:order)
        return cleaned_opts
      end

      # Takes the limit option to find and returns a uniform hash version of it.
      def hashize_limit(limit_opt)
        if( limit_opt.kind_of?(Hash) )
          return {:limit => nil, :offset => 0}.merge(limit_opt)
        elsif( limit_opt.kind_of?(Array) )
          return {:limit => limit_opt[0], :offset => limit_opt[1]||0}
        else
          return {:limit => (limit_opt&&limit_opt.to_i), :offset => 0}
        end
      end

      # Takes the order option to find and returns a uniform hash version of it.
      def hashize_order(order_opt)
        if( order_opt.kind_of?(Hash) )
          return order_opt
        elsif( order_opt.kind_of?(Array) )
          return order_opt.inject({}) {|hash,(key,direction)| hash[key] = direction || :asc; hash}
        elsif( order_opt.nil? )
          return {}
        else
          return {order_opt => :asc}
        end
      end
      
    end
  end
end

module Poro
  class Context
    include FinderMethods
  end
end