module Poro
  module Contexts
    # Not a practical real world context manager, this is a simple in-memory
    # store that uses a normal Ruby Hash.  The intended use for this context is
    # for building and testing code before a more realistic persistence backing
    # is available for your application.
    class HashContext < Context
      
      def initialize(klass)
        self.data_store = {}
        super(klass)
      end
      
      def fetch(id)
        obj = convert_to_plain_object( data_store[clean_id(id)] )
        callback_event(:after_fetch, obj)
        return obj
      end
      
      # Save the object in the underlying hash, using the object id as the key.
      def save(obj)
        callback_event(:before_save, obj)
        
        pk_id = self.primary_key_value(obj)
        if(pk_id.nil?)
          pk_id = obj.object_id
          self.set_primary_key_value(obj, pk_id)
        end
        
        data_store[pk_id] = convert_to_data(obj)
        
        callback_event(:after_save, obj)
        return obj
      end
      
      # Remove the object from the underlying hash.
      def remove(obj)
        callback_event(:before_remove, obj)
        
        pk_id = self.primary_key_value(obj)
        if( pk_id != nil )
          data_store.delete(pk_id)
          self.set_primary_key_value(obj, nil)
        end
        
        callback_event(:after_remove, obj)
        return obj
      end
      
      def convert_to_plain_object(data)
        transformed_data = callback_transform(:before_convert_to_plain_object, data)
        obj = transformed_data
        callback_event(:after_convert_to_plain_object, obj)
        return obj
      end
      
      def convert_to_data(obj)
        transformed_obj = callback_transform(:before_convert_to_data, obj)
        data = transformed_obj
        callback_event(:after_convert_to_data, data)
        return data
      end
      
      private
      
      # Searching a hash is incredibly slow because the following steps must
      # be taken:
      # 1. If there is an order, we first have to sort ALL values by the order.
      # 2. Then we must find all matching records.
      # 3. Then we must apply limit and offset to fetch the correct record.
      #
      # There are several optimizations to this that have already been done:
      # * If the conditions include the primary key, use fetch and drop that
      #   condition.
      # * If the offset is higher than the total number of stored records, then
      #    we know there will be no matches.
      #
      # There are several optimizations that can be made in the future:
      # * When matching the last key in the list, we can stop processing when
      #    we reach the limit+offset number of records.
      def find_all(opts)
        opts = clean_find_opts(opts)
        
        # If the offset is bigger than the stored number of records, we know that
        # we'll get nothing:
        return [] if( (opts[:limit]&&opts[:limit][:offset]).to_i > data_store.length )
        
        # If a search condition is the primary key, we can significantly limit our work.
        values = nil
        data = nil
        if( opts[:conditions].has_key?( self.primary_key ) )
          pk_value = opts[:conditions].delete(self.primary_key)
          obj = self.fetch( pk_value )
          values = obj.nil? ? [] : [obj]
          data = limit( filter( values, opts[:conditions]), opts[:limit] )
        else
          values = data_store.values
          data = limit( filter( sort( values, opts[:order] ), opts[:conditions] ), opts[:limit])
        end
        
        # Now do the search.
        return data.map {|data| convert_to_plain_object(data)}
      end
      
      # This is a highly inefficient implementation of the finder, as it finds
      # all records and selects the first matching one.
      def find_first(opts)
        opts[:limit] = 1
        return find_all(opts)[0]
      end
      
      # The data store has no built in finding mechanism, so this always
      # returns an empty array.
      def data_store_find_all(*args, &block)
        return []
      end
      
      # The data store has no built in finding mechanism, so this always
      # returns nil.
      def data_store_find_one(*args, &block)
        return nil
      end
      
      # Sorting works by taking the found value for two records and comparing them
      # with (a <=> b).to_i.  If the direction is :desc, this is multiplied by
      # -1.
      def sort(data, sort_opt)
        # If there are no sort options, don't sort.
        return data if sort_opt.nil? || sort_opt.empty?

        # Sort a copy of the data hash by building the comparison between elements.
        return data.dup.sort do |a,b|
          precedence = 0
          sort_opt.each do |key, direction|
            break if precedence != 0 # On the first non-zero precedence, we know who to put first!
            multiplier = direction.to_s=='desc' ? -1 : 1
            value_a = value_for_key(a, key)[:value]
            value_b = value_for_key(b, key)[:value]
            if( value_a!=nil && value_b!=nil )
              precedence = multiplier * (value_a <=> value_b).to_i
            elsif( value_a.nil? && value_b.nil? )
              precedence = 0
            elsif( value_a.nil? && value_b!=nil )
              precedence = multiplier * -1 # TODO: Which way does SQL or MongoDB sort nil?
            elsif( value_a!=nil && value_b.nil? )
              precedence = multiplier * 1 # TODO: Which way does SQL or MongoDB sort nil?
            end
          end
          precedence # Sort block return
        end
      end
      
      # Filters out records that, for each of the conditions in the hash,
      # have a value at the keypath and the value at that keypath matches the
      # desired value.
      def filter(data, conditions_opt)
        conditions_opt.inject(data) do |matches,(key, value)|
          keypath = key.to_s.split('.')
          matches.select do |record|
            value_info = value_for_key(record, keypath)
            value_info[:found] && value_info[:value] == value
          end
        end
      end
      
      def limit(data, limit_opt)
        if( !limit_opt.nil? && limit_opt[:limit] )
          return data[limit_opt[:offset].to_i, limit_opt[:limit].to_i] || []
        elsif( !limit_opt.nil? )
          return data[limit_opt[:offset].to_i .. -1] || []
        else
          return data
        end
      end
      
      # Returns a hash with the following keys:
      # [:found]   Returns true if the given keypath resolves to a value.
      # [:value]   The value found at the keypath.  This will be nil if none was
      #            found, but nil could be the real stored value as well!
      def value_for_key(record, keypath)
        # This is a recursive method, so while record looks good for an entry point
        # variable, obj is better when traversing.
        obj = record
        
        # Split the keypath if it is not an array already
        keypath = keypath.to_s.split('.') unless keypath.kind_of?(Array)

        # If we are at the end of hte keypath and the given object matches the
        # expected value, we have a match, otherwise we don't.
        #return {:matches => obj==match_value, :value => obj} if( keypath.empty? )
        return {:found => true, :value => obj} if (keypath.empty?)

        # If we aren't at the end of hte keypath, we get to descend one more level,
        # remembering to return false if we can't descend for some reason.
        key, *remaining_keys = keypath
        if( obj.kind_of?(Array) )
          return {:found => false, :value => nil} if key.to_i < 0 || key.to_i >= obj.length
          new_obj = obj[key.to_i]
        elsif( obj.kind_of?(Hash) )
          return {:found => false, :value => nil} unless obj.has_key?(key.to_s) || obj.has_key?(key.to_sym) || obj.has_key?(key.to_i)
          new_obj = obj[key.to_s] || obj[key.to_sym] || obj[key.to_i]
        else
          return {:found => false, :value => nil} unless key =~ /[_a-zA-z]([_a-zA-z0-9]*)/
          ivar = ('@'+key.to_s).to_sym
          return {:found => false, :value => nil} unless obj.instance_variable_defined?(ivar)
          new_obj = obj.instance_variable_get(ivar)
        end
        return send(__method__, new_obj, remaining_keys)
      end
      
    end
  end
end
    