module Poro
  module Contexts
    # Not a practical real world context manager, this is a simple in-memory
    # store that uses a normal Ruby Hash.  The intended use for this context is
    # for building and testing code before a more realistic persistence backing
    # is available for your application.
    class Hash < Context
      
      def initialize(klass)
        self.data_store = {}
        super(klass)
      end
      
      def fetch(id)
        return convert_to_plain_object(data_store[id])
      end
      
      def save(obj)
        raise SaveError, "Cannot save an object that can't have an ID." unless obj.respond_to?(:id)
        if( obj.id.nil? )
          raise SaveError, "Cannot save an object that cannot have an ID assigned to it." unless obj.respond_to?(:id=)
          obj.id = obj.object_id
        end
        
        data_store[obj.id] = convert_to_data(obj)
        return self
      end
      
      def remove(obj)
        raise RemoveError, "Cannot remove an object that can't have an ID." unless obj.respond_to?(:id)
        raise RemoveError, "Cannot remove an object that cannot have an ID assigned to it." unless obj.respond_to?(:id=)
        
        data_store.delete(obj.id)
        obj.id = nil
        return self
      end
      
      def convert_to_plain_object(data)
        return data
      end
      
      def convert_to_data(obj)
        return obj
      end
      
    end
  end
end
    