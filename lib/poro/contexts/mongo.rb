require 'set'

module Poro
  module Contexts
    # The MongoDB Context Adapter.
    #
    # Manages an object in MongoDB.
    #
    # WARNING: At this time, only objects that follow nice tree hierarchies can
    # be encoded.  Cyclical loops cannot be auto-encoded, and need embedded
    # objects to be managed with the parent pointers blacklisted.  This is a
    # TODO to fix.
    #
    # WARNING: Embedded objects of the same kind--which are referenced via a
    # DBRef, are re-fetched and re-saved every time the managing object is
    # fetched or saved.  Beware, then, that you can overwrite your own record.
    #
    # BUG: I am doing context checking against the object itself, and calling
    # save right on it.  I need to fetch the context directly!
    #
    # TODO: Instead of assuming 'id' as the primary key method, make it cusomizable.
    # This should be a context level method and persistify should honor it.
    #
    # This adapter recursively encodes the object according to the following
    # rules for each instance variable's value:
    #   1. If the object can be saved as a primitive, save it that way.
    #   2. If the object is managed by a Mongo context, save and encode it as a DBRef.
    #   3. If the object is managed by another context, save and store the class and id in a hash.
    #   4. Otherwise, encode all instance variables and the class, in a Hash.
    #
    # For Mongo represented objects, the instance variables that are encoded
    # can be controlled via any combination of the <tt>save_attributes</tt> and
    # <tt>save_attributes_blacklist</tt> properties.  The Context will start
    # with the save attributes (which defaults to all the instance variables),
    # and then subtract out the attributes in the blacklist.  Thus the blacklist
    # takes priority.
    class Mongo < Context
      
      # Takes the class for the context, and optionally the collection object
      # up front.  This can be changed at any time by setting the data store for
      # the Context.
      def inititalize(klass, collection=nil)
        # Require mongo.  We do it here so that it is only required when
        # we use this.  (How does this affect speed?  It seems this takes 1/30000 of a second.)
        require 'mongo'
        
        # Set-up the lists.
        @persistent_attributes_whitelist = nil
        @persistent_attributes_blacklist = nil
        
        # Initialize
        super(klass, collection)
      end
      
      attr_reader :persistent_attributes_whitelist
      attr_writer :persistent_attributes_whitelist
      
      attr_reader :persistent_attributes_blacklist
      attr_writer :persistent_attributes_blacklist
      
      def fetch(id)
        id = BSON::ObjectID.from_str(id.to_s) unless id.kind_of?(BSON::ObjectID) #TODO: Make it configurable as to if it tries to do this.
        return data_store.find_one(id)
      end
      
      def save(obj)
        data = convert_to_data(obj, :is_root_object => true)
        puts "DATA: #{data.inspect}"
        data_store.save(data)
        obj.id = (data['_id'] || data[:_id]) # The pk generator uses a symbol, while everything else uses a string!
        return obj
      end
      
      def remove(obj)
        return obj
      end
      
      def convert_to_plain_object(data)
        return data
      end
      
      # Converts the given object using this context's rules.
      #
      # Options:
      #   is_root_object:: if true, then will not treat as an embedded value.
      def convert_to_data(obj, opts={})
        puts "** convert_to_data(#{obj.inspect})"
        data = route_encode(obj, opts)
        puts "-- #{data.inspect}"
        return data
      end
      
      private
      
      # The computed final list of attributes to save.
      def instance_variables_to_save(obj)
        white_list = if( self.persistent_attributes_whitelist.nil? )
          obj.instance_variables.map {|ivar| ivar.to_s[1..-1].to_sym}
        else
          self.persistent_attributes_whitelist
        end
        black_list = self.persistent_attributes_blacklist || []
        return white_list - black_list - [:id] # Array difference is faster than Set difference.
      end
      
      # If the object is a MongoDB compatible primitive, return true.
      def mongo_primitive?(obj)
        return obj.kind_of?(Integer) || obj.kind_of?(Float) || obj.kind_of?(String) || obj.kind_of?(Time) || obj==true || obj==false || obj.nil? || obj.kind_of?(BSON::ObjectID) || obj.kind_of?(BSON::DBRef)
      end
      
      def route_encode(obj, opts={})
        if( obj.kind_of?(klass) && opts[:is_root_object] )
          return encode_self_managed_object(obj)
        elsif( obj.kind_of?(Hash) )
          return encode_hash(obj)
        elsif( obj.kind_of?(Array) )
          return encode_array(obj)
        elsif( obj.respond_to?(:context) && obj.context.kind_of?(self.class) )
          return encode_mongo_managed_object(obj)
        elsif( obj.respond_to?(:context) && !(obj.context.kind_of?(self.class)) )
          return encode_foreign_managed_object(obj)
        elsif( mongo_primitive?(obj) )
          return obj
        else
          return encode_object(obj)
        end
      end
      
      def encode_hash(hash)
        return hash.inject({}) do |hash,(k,v)|
          hash[k] = self.convert_to_data(value)
          hash
        end
      end
      
      def encode_array(array)
        return array.map {|o| self.convert_to_data(o)}
      end
      
      # Encode an object managed by this context.
      def encode_self_managed_object(obj)
        data = hashify_object(obj, instance_variables_to_save(obj))
        data['_id'] = obj.id unless obj.id.nil?
        data_store.pk_factory.create_pk(data) # This creates one only if it doesn't have it
        data['_class_name'] = obj.class.name
        return data
      end
      
      # Encode an object managed by this kind of context.  It encodes as a
      # DBRef if it is in the same database, and as a foreign managed object
      # if not.
      def encode_mongo_managed_object(obj)
        obj.save
        if( obj.context.data_store.db == data_store.db )
          return BSON::DBRef.new(obj.context.data_store.name, obj.id)
        else
          return encode_foreign_managed_object(obj)
        end
      end
      
      # Encode an object managed by a completely different kind of context.
      def encode_foreign_managed_object(obj)
        obj.save
        return {'id' => obj.id, '_class_name' => obj.class.name, 'context_class_name' => obj.context.class.name}
      end
      
      # Encode an object not managed by a context.
      def encode_object(obj)
        ivars = obj.instance_variables.map {|ivar| ivar.to_s[1..-1].to_sym}
        return hashify_object(obj, ivars)
      end
      
      # Turns an object into a hash, using the given list of instance variables.
      def hashify_object(obj, ivars)
        data = ivars.inject({}) do |hash, ivar_name|
          ivar_sym = ('@' + ivar_name.to_s).to_sym
          value = obj.instance_variable_get(ivar_sym)
          hash[ivar_name.to_s] = self.convert_to_data(value)
          hash
        end
        data['_class_name'] = obj.class.name
        return data
      end
      
    end
  end
end