module Poro
  # This is the abstract superclass of all Contexts.
  #
  # For find methods, see FindMethods.
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
    def self.configure_for_class(klass)
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
    
    # Returns true if there is a factory assigned to the application.
    def self.factory?
      ContextFactory.has_instance?
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
    # configuration and advanced usage, but can be dangerous to monkey with.
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
      obj = convert_to_plain_object( clean_id(nil) )
      callback_event(:after_fetch, obj)
      return obj
    end
    
    # Saves the given object to the persistent store using this context.
    #
    # Subclasses do not need to call super, but should follow the given rules:
    #
    # Returns the saved object.
    #
    # If the object has never been saved, it should be inserted and given
    # an id.  If the object has been added before, the id is used to update
    # the existing record.
    #
    # Raises an Error if save fails.
    def save(obj)
      callback_event(:before_save, obj)
      obj.id = obj.object_id if obj.respond_to?(:id) && obj.id.nil? && obj.respond_to?(:id=)
      callback_event(:after_save, obj)
      return obj
    end
    
    # Remove the given object from the persisten store using this context.
    #
    # Subclasses do not need to call super, but should follow the given rules:
    #
    # Returns the removed object.
    #
    # If the object is successfully removed, the id is set to nil.
    #
    # Raises an Error is the remove fails.
    def remove(obj)
      callback_event(:before_remove, obj)
      obj.id = nil if obj.respond_to?(:id=)
      callback_event(:after_remove, obj)
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
      transformed_data = callback_transform(:before_convert_to_plain_object, data)
      obj = transformed_data
      callback_event(:after_convert_to_plain_object, obj)
      return obj
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
      transformed_obj = callback_transform(:before_convert_to_data, obj)
      data = transformed_obj
      callback_event(:after_convert_to_data, data)
      return data
    end
    
    private 
    
    # Given a value that represents an ID, scrub it to produce a clean ID as
    # is needed by the data store for the context.
    #
    # This is used by methods like <tt>fetch</tt> and <tt>find_for_ids</tt> to
    # convert the IDs from whatever types the user passed, into the correct
    # values.
    def clean_id(id)
      return id
    end
    
  end
end




module Poro
  class Context
    # A mixin that contains all the context find methods.
    #
    # The methods are split into three groups:
    # [FindMethods] Contains the methods that a developer should use but that
    #               a Context author should never need to override.
    # [FindMethods::RootMethods] Contains the methods that a developer should
    #                            never need to use, but that a Context author
    #                            needs to override.
    # [FindMethods::HelperMethods] Some private helper methods that rarely need
    #                              to be used or overriden.
    #
    # Note that <tt>fetch</tt> is considered basic functionality and not a 
    # find method, even though it technically finds by id.
    #
    # Subclasses are expected to override the methods in RootMethods.
    module FindMethods
      
      def self.included(mod) # :nodoc:
        mod.send(:include, RootMethods)
        mod.send(:private, *RootMethods.instance_methods)
        mod.send(:include, HelperMethods)
        mod.send(:private, *HelperMethods.instance_methods)
      end
      
      # Provides the delegate methods for the find routines.
      #
      # These methods are made private so that developers use the main find
      # methods.  This makes it easier to change behavior in the future due to
      # the bottlenecking.
      #
      # Subclasses of Context should override all of these.
      # See the inline subclassing documentation sections for each method for details.
      module RootMethods
        
        # Returns an array of all the records that match the following options.
        #
        # One ususally calls this through <tt>find</tt> via the :all or :many argument.
        #
        # See <tt>find</tt> for more help.
        #
        # === Subclassing
        #
        # Subclasses MUST override this method.
        #
        # Subclases usually convert the options into a call to <tt>data_store_find_all</tt>.
        def find_all(opts)
          return data_store_find_all(opts)
        end
        
        # Returns the first record that matches the following options.
        # Use of <tt>fetch</tt> is more convenient if finding by ID.
        #
        # One usually calls this through <tt>find</tt> via the :first or :one argument.
        #
        # See <tt>find</tt> for more help.
        #
        # === Subclassing
        #
        # Subclasses MUST override this method!
        #
        # They usually take one of several tacts:
        # 1. Convert tothe options and call <tt>data_store_find_first</tt>.
        # 2. Set the limit to 1 and call <tt>find_all</tt>.
        def find_first(opts)
          hashize_limit(opts[:limit])[:limit] = 1
          return find_all(opts)
        end
        
        # Calls the relevant finder method on the underlying data store, and
        # converts all the results to plain objects.
        #
        # One usually calls thrigh through the <tt>data_store_find</tt> method
        # with the :all or :many arument.
        #
        # Use of this method is discouraged as being non-portable, but sometimes
        # there is no alternative but to get right down to the underlying data
        # store.
        #
        # Note that if this method still isn't enough, you'll have to use the
        # data store and convert the objects yourself, like so:
        #   SomeContext.data_store.find_method(arguments).map {{|data| SomeContext.convert_to_plain_object(data)}
        #
        # === Subclassing
        #
        # Subclasses MUST override this method.
        #
        # Subclasses are expected to return the results converted to plain objects using
        #   self.convert_to_plain_object(data)
        def data_store_find_all(*args, &block)
          return [].map {|data| convert_to_plain_object(data)}
        end
        
        # Calls the relevant finder method on the underlying data store, and
        # converts the result to a plain object.
        #
        # One usually calls thrigh through the <tt>data_store_find</tt> method
        # with the :first or :one arument.
        #
        # Use of this method is discouraged as being non-portable, but sometimes
        # there is no alternative but to get right down to the underlying data
        # store.
        #
        # Note that if this method still isn't enough, you'll have to use the
        # data store and convert the object yourself, like so:
        #   SomeContext.convert_to_plain_object( SomeContext.data_store.find_method(arguments) )
        #
        #
        # === Subclassing
        # 
        # Subclasses MUST override this method.
        #
        # Subclasses are expected to return the result converted to a plain object using
        #   self.convert_to_plain_object(data)
        def data_store_find_first(*args, &block)
          return convert_to_plain_object(nil)
        end
        
        # Returns the records that correspond to the passed ids (or array of ids).
        #
        # One usually calls this by giving an array of IDs to the <tt>find</tt> method.
        #
        # === Subclassing
        #
        # Subclasses SHOULD override this method.
        #
        # By default, this method aggregates separate calls to fetch.  For
        # most data stores this makes N calls to the server, decreasing performance.
        #
        # When possible, this method should be overriden by subclasses to be more
        # efficient, probably calling a <tt>find_all</tt> with the IDs, as
        # filtered by the <tt>clean_id</tt> private method.
        def find_with_ids(*ids)
          ids = ids.flatten
          return ids.map {|id| fetch(id)}
        end
        
      end
      
      # Contains some private helper methods to help process finds.  These
      # rarely need to be used or overriden by Context subclasses.
      module HelperMethods
      
        # Cleans the find opts.  This makes it so that no matter which (legal)
        # style that they give their options to find, they are made into a single
        # standard format that the subclasses can depend on.
        def clean_find_opts(opts)
          cleaned_opts = opts.dup
          cleaned_opts[:limit] = hashize_limit(opts[:limit]) if opts.has_key?(:limit)
          cleaned_opts[:order] = hashize_order(opts[:order]) if opts.has_key?(:order)
          return cleaned_opts
        end
      
        # Takes the limit option to find and returns a uniform hash version of it.
        #
        # The hash has the form:
        #  {:limit => (integer || nil), :offset => (integer)}
        #
        # Note that a limit of nil means that all records shoudl be returned.
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
        #
        # Returns a hash of each sort key followed by either :asc or :desc.  If
        # there are no sort keys, this returns an empty hash.
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
      # === Subclassing
      #
      # Subclasses MUST NOT override this method.
      #
      # This method delegates out its calls to other methods that should be
      # overridden by subclasses.
      def find(arg, opts={})
        if(arg == :all || arg == :many)
          return find_all(opts)
        elsif( arg == :first || arg == :one)
          return find_first(opts)
        elsif( arg.respond_to?(:map) )
          return find_with_ids(arg)
        else
          return fetch(arg)
        end
      end
      
      # Forwards the arguments and any block to the data store's find methods,
      # and returns plain ol' objects as the result.
      # 
      # WARNING: This normally should not be used as its behavior is dependent
      # upon the underlying data store, however sometimes there is no equivalent
      # to the functionality offered by the data store given by the normal find
      # method.
      #
      # The first argument must be one of:
      # * :all or :many
      # * :first or :one
      def data_store_find(first_or_all, *args, &block)
        if(first_or_all == :all || first_or_all == :many)
          return data_store_find_all(*args, &block)
        elsif( first_or_all == :first || first_or_all == :one)
          return data_store_find_first(*args, &block)
        else
          raise ArgumentError, "#{__method__} expects the first argument to be one of :all, :many, :first, or :one."
        end
      end
      
    end
  end
end

module Poro
  class Context
    # A mixin to support callbacks.  There are three kinds of callbacks:
    # [Events] Events are callbacks that are passed a handle to the object when
    #          a particular kind of event has occured.  These may destructively
    #          edit objects.
    # [Transform] Transforms are callbacks where each handler is passed the
    #             result of the previous transform, and may return any value.
    #             The issuing object then uses the final value in some way.
    # [Filters] Calls each callback in sequence, pasing in the issuing object.
    #           Terminates execution on the first callback that is "false" (as
    #           determined by an if statement), or when there are no callbacks
    #           left. Gives the issuing object the result of the last block.
    #
    # Contexts issue the following event callbacks:
    # [:before_save] Called before save; passes the object that is going to be saved.
    # [:after_save] Called after save; passes the object that was saved.
    # [:before_remove] Called before removing an object from persistent storage; passes the object that will be removed.
    # [:after_remove] Called after removing an object from persistent storage; passes the object that was removed.
    # [:after_fech] Called after an object is fetched from the persistent store; passes the object that was fetched.
    # [:after_convert_to_plain_object] Called after an object is converted to a plain object from the persistent store but before it is used; passes the plain object.
    # [:after_convert_to_data] Called after an object is converted to the persistent store's data structure but before it is used; passes the data store's data structure.
    #
    # Contexts issue the following transform callbacks:
    #
    # [:before_convert_to_plain_object] Called just before a context converts
    #                                   persistent store data to a plain ruby object;
    #                                   is passed the persistent store data object;
    #                                   the result is what is converted.
    #                                   
    #                                   In most cases it is better to use the
    #                                   +after_convert_to_plain_object+ callback event.
    # [:before_convert_to_data] Called just before a context converts
    #                           a plain ruby object to persistent store data;
    #                           is passed the plain ruby object;
    #                           the result is what is converted.
    #                           
    #                           In most cases it is better to use the
    #                           +before_convert_to_plain_object+ callback event.
    module CallbackMethods
      
      # Return the raw array of callbacks.  This can be manipulated if more
      # straightforward methods don't do the trick, but usually this is
      # a consequence of trying to solve the problem wrong.
      #
      # While usually a kind of Proc, callbacks may be any object that responds
      # to call.
      def callbacks(event)
        @event_callbacks ||= {}
        key = event.to_sym
        @event_callbacks[key] ||= []
        return @event_callbacks[key]
      end
      
      # Register a callback for a given event.
      def register_callback(event, &block)
        callbacks(event) << block
      end
      
      # Clear all callbacks for a given event.
      #
      # This can be dangerous because
      def clear_callbacks(event)
        callbacks(event).clear
      end
      
      private
      
      # Fires the callbacks for the given event; returns the object supplied
      # for calling.
      #
      # * Each registered callback is given the object issued with the call.
      # * Depending on your uses, the callback may be destructive of the passed object.
      # * The callback returns are ignored.
      #
      # Registration of no callbacks results in no callbacks being called.
      def callback_event(event, obj)
        callbacks(event).each {|callback| callback.call(obj)}
        return obj
      end
      
      # Transforms an object through a callback chain; returns the transformed
      # object.
      #
      # * Each registered callback is given the result of the previous callback.
      # * Callbacks may return the original object (modified or unmodified), a
      #   copy of the original object (modified or unmodified), or an entirely
      #   new object, depending on how the result is used.
      # * The callback return is passed into the next callback, with the last
      #   return being called to the initial caller.
      #
      # Registration of no callbacks results in the return of the original object.
      def callback_transform(event, initial_obj)
        return callbacks(event).inject(initial_obj) {|obj, callback| callback.call(obj)}
      end
      
      # Executes callbacks until the last true-valued filter; returns the last
      # true valued object.
      #
      # By convention, filter events should end in a question mark to make it
      # clear that the true/false value is important.
      #
      # * Each registered callback is given the original object, making this
      #   behave more like an event than a transform.
      # * Filters are expected to be non-destructive, as they are used to
      #   determine if an action should take place, rather than to take an
      #   action.
      # * If the return of a callback is false-values (as determined by an +if+
      #   expression), then the filter chain is halted and the value is returned;
      #   otherwise, the value returned from the last callback is returned.
      #
      # Registration of no callbacks results in the return of the +default_value+
      # argument, which--if not provided--is set to true.
      def callback_filter?(event, obj, default_result=true)
        result = default_result
        callbacks(event).each do |callback|
          result = callback.call(obj)
          break unless result
        end
        return result
      end
      
    end
  end
end

module Poro
  class Context
    include FindMethods
    include CallbackMethods
  end
end