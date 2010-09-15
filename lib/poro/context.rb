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
    
    # Initizialize this context for the given class.  Yields self if a block
    # is given, so that instances can be easily configured at instantiation.
    #
    # Only subclasses are expected to use this method (through calls to super),
    # and they should set the data store for the instance as the second argument.
    def initialize(klass, data_store=nil)
      @klass = klass
      @data_store = data_store
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
    
    # Fetches the object from the store with the given id, or returns nil
    # if there are none matching.
    def fetch(id)
      return nil
    end
    
    # Saves the given object to the persistent store.
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
    
    # Remove the given object from the persisten store.
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
    def convert_to_plain_object(data)
      return data
    end
    
    # Convert a plain ol' ruby object into the data store data format this
    # context represents.
    def convert_to_data(obj)
      return obj
    end
    
  end
end