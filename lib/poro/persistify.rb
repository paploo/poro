module Poro
  # When this module is mixed into an object, it adds the required persistence
  # methods to the object, and passes the call off to the persistence engine.
  #
  # Architecturally, this module adds methods that delegate the responsibility
  # of persistence to the persistence engine, namely the associated methods on
  # the Context.
  #
  # While most clients will prefer to implement persistence on an object using
  # this mixin, it is possible to use persistence without it.  However, if you
  # do it yourself, you will either want to implement the methods defined below,
  # or know that you don't conform to normal Poro usage.
  #
  # See Persistify::ClassMethods and Persistify::InstanceMethods for the methods
  # added by this mixin.
  module Persistify
    
    def self.included(mod) # :nodoc:
      mod.send(:extend, ClassMethods)
      mod.send(:include, InstanceMethods)
    end
    
    # These methods are added as class methods when including Persistify.
    # See Persistify for more information.
    module ClassMethods
      # Find the object for the given id.
      def find(id)
        return context.find(id)
      end
      
      # Get the context instance for this class.
      def context
        return ContextManager.instance.fetch(self)
      end
    end
    
    # These methods are addes as instance methods when including Persistify.
    # See Persistify for more information.
    module InstanceMethods
      
      # Save the given object to persistent storage.
      def save
        return context.save(self)
      end
      
      # Remove the given object from persistent storage.
      def delete
        return context.delete(self)
      end
      
      # Return the context instance for this object.
      def context
        return self.class.context
      end
    end
    
  end
end