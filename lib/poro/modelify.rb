module Poro
  # When this module is mixed into a a persistent object, it adds the
  # object oriented methods directly to the class, making it behave like a model
  # in other ORMs.
  #
  # If this module is not mixed in, the object can still persist, but the context
  # must be directly accessed to fetch, save, and remove the data.
  #
  # Additionally, this module also ensures that the appropriate
  # primary key accessor methods exist on the object, creating them if necessary.
  #
  # WARNING: You should configure the primary keys on the class' Context before
  # including this module if you want to use an accessor other than the
  # Context's default.
  #
  # See Modelify::ClassMethods and Modelify::InstanceMethods for the methods
  # added by this mixin.
  #
  # = TODO: Piecewise Modelfication
  #
  # Modelfication should be done in a piece-meal way, so that we can layer
  # in features such as pk accesor generation, basic model methods, find methods,
  # and hook methods.  We may still keep this top-level include to add the full
  # suite, but we should break up the pieces.  (In doing this, we could to manage
  # dependencies so that we get the basic pieces included in when we need things
  # they depend on, but by not managing this, it gives more flexability for
  # advanced users to replace segments.
  module Modelify
    
    def self.included(mod) # :nodoc:
      mod.send(:extend, ClassMethods)
      mod.send(:include, InstanceMethods)
      mod.send(:include, FindMethods)
      
      context = Context.fetch(mod)
      pk = context.primary_key.to_s.gsub(/[^A-Za-z0-9]/, '_').strip
      raise NameError, "Cannot create a primary key method from #{context.primary_key.inspect}" if pk.nil? || pk.empty?
      mod.class_eval("def #{pk}; return @#{pk}; end")
      mod.class_eval("def #{pk}=(value); @#{pk} = value; end")
    end
    
    # These methods are added as class methods when including Modelify.
    # See Modelify for more information.
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
    
    # These methods are addes as instance methods when including Modelify.
    # See Modelify for more information.
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
    
    module FindMethods
      
      def self.included(mod)
        mod.send(:extend, ClassMethods)
      end
      
      module ClassMethods
        def find(arg, opts={})
          return context.find(arg, opts)
        end
        
        def data_store_find(first_or_all, *args, &block)
          return context.data_store_find(first_or_all, *args, &block)
        end
      end
      
    end
    
  end
end