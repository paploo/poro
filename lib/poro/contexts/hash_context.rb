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
        return convert_to_plain_object( data_store[clean_id(id)] )
      end
      
      # Searching a hash is incredibly slow because the following steps must
      # be taken:
      # 1. If there is an order, we first have to sort ALL values by the order.
      # 2. Then we must find all matching records.
      # 3. Then we must apply limit and offset to fetch the correct record.
      #
      # There are several optimizations that can be made in the future:
      # 1. When matching the last key in the list, we can stop processing when
      #    we reach the limit+offset number of records.
      # 2. If the offset is higher than the total number of stored records, then
      #    we know there will be no matches.
      def find_all(opts)
        opts = clean_find_opts(opts)
        data = limit( filter( sort( data_store.dup, opts[:order] ), opts[:conditions] ), opts[:limit])
        return data.map {|data| convert_to_plain_object(data)}
      end
      
      # This is a highly inefficient implementation of the finder, as it finds
      # all records and selects the first matching one.
      def find_first(opts)
        opts[:limit] = 1
        return find_all(opts)[0]
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
      
      private
      
      def clean_id(id)
        return id && id.to_i
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
    