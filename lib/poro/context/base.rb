module Poro
  module Context
    class Base
      
      # Initizialize this context for the given class.  Yields self if a block
      # is given.
      def initialize(klass)
        @klass = klass
        @data_store = nil # Subclasses should set this to something useful.
        yield(self) if block_given?
      end
      
      # The class that this context instance services.
      attr_reader :klass
      
      # The raw data store backing this context.  This is useful for advanced
      # usage, such as special queries.  Be aware that whenever you use this,
      # there is tight coupling with the underlying persistence store!
      attr_reader :data_store
      
      # Fetches the object from the store with the given identifier.
      def fetch(id)
        return nil
      end
      
      # Saves the given object to the persistent store.  Returns self.
      #
      # This should assign an identifier to the object if save is successful.
      def save(obj)
        obj.id = obj.object_id if obj.respond_to?(:id=)
        return obj
      end
      
      # Remove the given object from the persisten store.  Returns self.
      #
      # This should remove the identifier from the object if the remove is
      # successful.
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
end