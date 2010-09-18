module Poro
  module Util
    module ModuleFinder
      
      # Finds the given module by string.
      #
      # Arguments:
      # [arg] The module/class name to find.
      # [relative_root] If given, tries to find the requested class/module
      #                 within this module/class.  May be a string.
      # [strict] Normally--mostly like Ruby--a top-level class will be returned
      #          at any step if no module/class matches in the namespace it is
      #          searching.  If this is true, then a last check is made to see
      #          if the returned module/class is actually inside of the relative
      #          root.
      #
      # If given a class, it returns it directly.  TODO: Make it look it up if
      # relative_root is not Module or Object.
      def self.find(arg, relative_root=Module, strict=false)
        # If the argument is a kind of class, just return right away.
        return arg if arg.kind_of?(Module) || arg.kind_of?(Class)
        
        # Now we need to treat it as a string:
        arg = arg.to_s
        raise NameError, "Could not find a module or class from nothing." if arg.nil? || arg.empty?
        
        # First, define the recursive function.
        recursive_resolve = lambda do |curr_mod, names|
          head, *rest = names.to_a
          if( head.nil? && rest.empty? )
            curr_mod
          elsif( !(head.to_s.empty?) && curr_mod.respond_to?(:const_defined?) && curr_mod.const_defined?(head) )
            recursive_resolve.call( curr_mod.const_get(head), rest)
          else
            raise NameError, "Could not find a module or class from #{arg.inspect}"
          end
        end
        
        # If starting with ::, then the constant is aboslutely referenced.
        relative_root = Module if arg[0,2]=='::'
        
        # Split into names
        start_index = arg[0,2]=='::' ? 2 : 0
        mod_names = arg[start_index..-1].split('::')
        
        # Now get the module or class.
        relative_root = self.send(__method__, relative_root)
        mod = recursive_resolve.call(relative_root, mod_names)
        
        # Now, if we are strict, verify it is of the type we are looking for.
        if (relative_root!=Module || relative_root!=Object) && !(mod.name.include?(relative_root.name))
          base_message = "Could not find a module or class #{mod.name.inspect} inside of #{relative_root.name.inspect}"
          if( strict )
            raise NameError, base_message
          else
            STDERR.puts "WARNING: #{base_message}, top level mod/class used instead."
          end
        end
        
        # Return
        return mod
      end
      
    end
  end
end