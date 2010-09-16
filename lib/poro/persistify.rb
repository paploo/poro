module Poro
  # Include this module into any class in order to flag it for persistence.
  #
  # This is the only required change to a class in order to make it persistent.
  # This flags it so that the factories know that it is okay to generate a
  # context for this class and persist it.
  #
  # The only method this adds is a convenience class method for configuring
  # the Context instance that backs the class it is included in.
  #
  # This module represents the only required breech of the hands off your code
  # philosophy that Poro embodies.
  #
  # For those looking to add more model like behaviors, include Poro::Modelify
  # as well.
  module Persistify
    
    def self.included(mod)
      mod.send(:extend, ClassMethods)
    end
    
    module ClassMethods
      
      def configure_context(&configuration_block)
        return Context.configure_for_class(self, &configuration_block)
      end
      
    end
    
  end
end