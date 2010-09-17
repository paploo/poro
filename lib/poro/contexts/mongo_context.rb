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
    class MongoContext < Context
      # A map of all the collection names registered for this kind of context.
      # This is to facilitate DBRef dereferencing, even when your class doesn't
      # match the 
      @@collection_map = {}
      
      # Takes the class for the context, and optionally the collection object
      # up front.  This can be changed at any time by setting the data store for
      # the Context.
      def initialize(klass)
        # Require mongo.  We do it here so that it is only required when
        # we use this.  (How does this affect speed?  It seems this takes 1/30000 of a second.)
        require 'mongo'
        
        # Set-up the lists.
        @persistent_attributes_whitelist = nil
        @persistent_attributes_blacklist = nil
        
        # Initialize
        super(klass)
      end
      
      # Set the data store to the given collection.
      def data_store=(collection)
        @@collection_map.delete(self.data_store && data.store.name) # Clean-up the old record in case we change names.
        @@collection_map[collection.name] = self unless collection.nil? # Create the new record.
        super(collection)
      end
      
      attr_reader :persistent_attributes_whitelist
      attr_writer :persistent_attributes_whitelist
      
      attr_reader :persistent_attributes_blacklist
      attr_writer :persistent_attributes_blacklist
      
      def fetch(id)
        id = BSON::ObjectID.from_str(id.to_s) unless id.kind_of?(BSON::ObjectID) #TODO: Make the transform configurable, mongo doesn't require an ObjectID as the key.
        data = data_store.find_one(id)
        return convert_to_plain_object(data)
      end
      
      def save(obj)
        data = convert_to_data(obj)
        data_store.save(data)
        set_primary_key_value(obj, (data['_id'] || data[:_id])) # The pk generator uses a symbol, while everything else uses a string!
        return obj
      end
      
      def remove(obj)
        return obj
      end
      
      def convert_to_plain_object(data, state_info={})
        #@decode_depth ||= 0
        #@decode_depth += 1
        #puts "**[#{@decode_depth}] convert_to_plain_object(#{data.inspect})"
        obj = route_decode(data, state_info)
        #puts "--[#{@decode_depth}] #{obj.inspect}"
        #@decode_depth -= 1
        return obj
      end
      
      def convert_to_data(obj, state_info={})
        #@encode_depth ||= 0
        #@encode_depth += 1
        #puts "**[#{@encode_depth}] convert_to_data(#{obj.inspect})"
        data = route_encode(obj, state_info)
        #puts "--[#{@encode_depth}] #{data.inspect}"
        #@encode_depth -= 1
        return data
      end
      
      # =============================== PRIVATE ===============================
      private
      
      # The computed list of instance variables to save, taking into account
      # white lists, black lists, and primary keys.
      def instance_variables_to_save(obj)
        white_list = if( self.persistent_attributes_whitelist.nil? )
          obj.instance_variables.map {|ivar| ivar.to_s[1..-1].to_sym}
        else
          self.persistent_attributes_whitelist
        end
        black_list = self.persistent_attributes_blacklist || []
        # Note that this is significantly faster with arrays than sets.
        # TODO: Only remove the primary key if it is not in the white list!
        return white_list - black_list - [self.primary_key]
      end
      
      # If the object is a MongoDB compatible primitive, return true.
      def mongo_primitive?(obj)
        return(
          obj.kind_of?(Integer) ||
          obj.kind_of?(Float) ||
          obj.kind_of?(String) ||
          obj.kind_of?(Time) ||
          obj==true ||
          obj==false ||
          obj.nil? ||
          obj.kind_of?(BSON::ObjectID) ||
          obj.kind_of?(BSON::DBRef)
        )
      end
      
      # Turns an object into a hash, using the given list of instance variables.
      def hashify_object(obj, ivars)
        data = ivars.inject({}) do |hash, ivar_name|
          ivar_sym = ('@' + ivar_name.to_s).to_sym
          value = obj.instance_variable_get(ivar_sym)
          hash[ivar_name.to_s] = self.convert_to_data(value, :embedded => true)
          hash
        end
        data['_class_name'] = obj.class.name
        return data
      end
      
      # Creates an object of a given class or class name, using the given hash of
      # of attributes and encoded values.
      def instantiate_object(klass_or_name, attributes)
        # Translate class name.
        klass = Util::ModuleFinder.find(klass_or_name)
        
        # Allocate the instance (use allocate and not new because we have all the state variables saved).
        obj = klass.allocate
        
        # Iterate over attributes injecting.
        attributes.each do |name, encoded_value|
          next if name.to_s == '_class_name' || name.to_s == '_id'
          ivar_sym = ('@' + name.to_s).to_sym
          value = self.convert_to_plain_object(encoded_value, :embedded => true)
          obj.instance_variable_set(ivar_sym, value)
        end
        
        # Return the result.
        return obj
      end
      
      # =============================== ENCODING ===============================
      
      # Routes the encoding of an object to the appropriate method.
      def route_encode(obj, state_info={})
        if( obj.kind_of?(klass) && !state_info[:embedded] )
          return encode_self_managed_object(obj)
        elsif( obj.kind_of?(Hash) && obj.has_key?('_namespace') )
          return encode_db_ref
        elsif( obj.kind_of?(Hash) )
          return encode_hash(obj)
        elsif( obj.kind_of?(Array) )
          return encode_array(obj)
        elsif( obj.kind_of?(Class) )
          return encode_class(obj)
        elsif( Context.managed_class?(obj.class) && Context.fetch(obj.class).kind_of?(self.class) )
          return encode_mongo_managed_object(obj)
        elsif( Context.managed_class?(obj.class))
          return encode_foreign_managed_object(obj)
        elsif( mongo_primitive?(obj) )
          return obj
        else
          return encode_unmanaged_object(obj)
        end
      end
      
      # Recursively encode a hash's contents.
      def encode_hash(hash)
        return hash.inject({}) do |hash,(k,v)|
          hash[k] = self.convert_to_data(value, :embedded => true)
          hash
        end
      end
      
      # Recursively encode an array's contents.
      def encode_array(array)
        return array.map {|o| self.convert_to_data(o, :embedded => true)}
      end
      
      # Encode a class.
      def encode_class(klass)
        return {'_class_name' => klass.class, 'name' => klass.name}
      end
      
      # Encode a hash that came from a DBRef dereferenced and decoded by this context.
      #
      # This will save the hash when its owning object is saved!
      def encode_db_ref(hash)
        namespace = hash['_namespace'].to_s
        id = hash['_id']
        mongo_db = self.data_store.db
        if( mongo_db.collection_names.include?(namespace) )
          h = hash.dup # We want to be non-destructive here!
          h.delete['_namespace']
          mongo_db[namespace].save(h)
        end
        return BSON::DBRef.new(namespace, id)
      end
      
      # Encode an object not managed by a context.
      def encode_unmanaged_object(obj)
        ivars = obj.instance_variables.map {|ivar| ivar.to_s[1..-1].to_sym}
        return hashify_object(obj, ivars)
      end
      
      # Encode an object managed by this context.
      def encode_self_managed_object(obj)
        data = hashify_object(obj, instance_variables_to_save(obj))
        data['_id'] = primary_key_value(obj) unless primary_key_value(obj).nil?
        data_store.pk_factory.create_pk(data) # Use the underlying adapter's paradigm for lazily creating the pk.
        data['_class_name'] = obj.class.name
        return data
      end
      
      # Encode an object managed by this kind of context.  It encodes as a
      # DBRef if it is in the same database, and as a foreign managed object
      # if not.
      def encode_mongo_managed_object(obj)
        # If in the same data store, we do a DBRef.  This is the usual case.
        # But we do need to save it if it is stored in a different database!
        obj_context = Context.fetch(obj)
        if( obj_context.data_store.db == self.data_store.db )
          obj_context.save(obj)
          obj_id = obj_context.primary_key_value(obj)
          obj_collection_name = obj_context.data_store.name
          return BSON::DBRef.new(obj_collection_name, obj_id)
        else
          # Treat as if in a foreign database
          return encode_foreign_managed_object(obj)
        end
      end
      
      # Encode an object managed by a completely different kind of context.
      def encode_foreign_managed_object(obj)
        obj_context = Context.fetch(obj)
        obj_context.save(obj)
        obj_id = obj_context.primary_key_value(obj)
        return {'id' => obj_id, '_class_name' => obj.class.name, 'managed' => true}
      end
      
      # =============================== DECODING ===============================
      
      # Route the decoding of data from mongo.
      def route_decode(data, state_info={})
        if( data && data.kind_of?(Hash) && data['_class_name'] )
          return route_decode_stored_object(data, state_info)
        else
          return route_decode_stored_data(data, state_info)
        end
      end
      
      # If the data doesn't directly encode an object, then this method knows
      # how to route the decoding.
      def route_decode_stored_data(data, state_info={})
        if( data.kind_of?(Hash) )
          return decode_hash(data)
        elsif( data.kind_of?(Array) )
          return decode_array(data)
        elsif( data.kind_of?(BSON::DBRef) ) # This is a literal that we want to intercept.
          return decode_db_ref(data)
        else # mongo_primitive?(data) # Explicit check not necessary.
          return data
        end
      end
      
      # If the data directly encodes an object, then this methods knows
      # how to route decoding.
      def route_decode_stored_object(data, state_info={})
        class_name = data['_class_name'].to_s
        if( class_name == 'Class' )
          return decode_class(data)
        elsif( class_name == self.klass.to_s )
          return decode_self_managed_object(data)
        elsif( class_name && data['managed'] )
          return decode_foreign_managed_object(data)
        else
          return decode_object(data)
        end
      end
      
      # Decode a hash, recursing through its elements.
      def decode_hash(hash)
        return hash.inject({}) do |hash,(k,v)|
          hash[k] = self.convert_to_plain_object(v, :embedded => true)
          hash
        end
      end
      
      # Decode an array, recursing through its elements.
      def decode_array(array)
        array.map {|o| self.convert_to_plain_object(o, :embedded => true)}
      end
      
      # Decode a class reference.
      def decode_class(class_data)
        return Util::ModuleFinder.find(class_data['name'])
      end
      
      # Decode a BSON::DBRef.  If there is a context for the reference, it is
      # wrapped in that object type.  If there is no context, it is left as
      # a DBRef so that it will re-save as a DBRef (otherwise it'll save as a
      # hash of that document!)
      #
      # Note that one would think we'd be able to recognize any hash with '_id'
      # as an embedded document that needs a DBRef, and indeed we can.  But we
      # won't know where to re-save it because we won't know the collection anymore,
      # so we add '_namespace' to the record and strip it out on a save.
      def decode_db_ref(dbref)
        context = @@collection_map[dbref.namespace.to_s]
        if( context )
          puts 'has-context'
          value = context.data_store.db.dereference(dbref)
          puts value.inspect
          return context.convert_to_plain_object(value, :embedded => false) # We want it to work like a standalone object, so don't treat as embedded.
        elsif self.data_store.db.collection_names.include?(dbref.namespace.to_s)
          puts 'no-context, in-db'
          value = context.data_store.db.dereference(dbref)
          value['_namespace'] = dbref.namespace.to_s
          return value
        else
          puts 'no-context, no-db'
          return dbref
        end
      end
      
      # Decode a self managed object
      def decode_self_managed_object(data)
        # Get the class and id.  Note these are auto-stripped by instantiate_object.
        class_name = data['_class_name']
        id = data['_id']
        # Instantiate.
        obj = instantiate_object(class_name, data)
        # Set the pk
        self.set_primary_key_value(obj, id)
        # Return
        return obj
      end
      
      # Decode a foreign managed object.  This is a matter of finding its
      # Context and asking it to fetch it.
      def decode_foreign_managed_object(data)
        klass = Util::ModuleFinder.find(data['_class_name'])
        context = Context.fetch(klass)
        if( context )
          context.find(data['id'])
        else
          return data
        end
      end
      
      # Decode the given unmanaged object.  If the class cannot be found, then just give
      # back the underlying hash.
      def decode_unmanaged_object(data)
        begin
          klass = Util::ModuleFinder.find(data['_class_name']) # The class name is autostripped in instantiate_object
          return instantiate_object(klass, data)
        rescue NameError
          return data
        end
      end
      
    end
  end
end