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
  #
  # Additionally, primary key methods are automatically added by this mixin using
  # the context to decide what the method should be named.  These additions will
  # not overwrite existing methods.
  module Persistify
    
    def self.included(mod) # :nodoc:
      mod.send(:extend, ClassMethods)
      mod.send(:include, InstanceMethods)
      
      # TODO: Declaring these here is easy and convenient, but makes it impossible to configure the pk right after including Persistify.
      context = Context.fetch(mod)
      pk = context.primary_key.to_s.gsub(/[^A-Za-z0-9]/, '_').strip
      raise NameError, "Cannot create a primary key method from #{context.primary_key.inspect}" if pk.nil? || pk.empty?
      mod.class_eval("def #{pk}; return @#{pk}; end")
      mod.class_eval("def #{pk}=(value); @#{pk} = value; end")
    end
    
    # These methods are added as class methods when including Persistify.
    # See Persistify for more information.
    module ClassMethods
      # Find the object for the given id.
      def fetch(id)
        return context.fetch(id)
      end
      
      # Get the context instance for this class.
      def context
        return Context.fetch(self)
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
      def remove
        return context.remove(self)
      end
      
      # Return the context instance for this object.
      def context
        return Context.fetch(self)
      end
    end
    
  end
end