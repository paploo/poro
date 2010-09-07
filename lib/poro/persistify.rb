module Poro
  module Persistify
  
    def self.included(mod)
      mod.send(:extend, ClassMethods)
      mod.send(:include, InstanceMethods)
    end
  
    module ClassMethods
      def find(id)
        return context.find(id)
      end
    
      def context
        return ContextManager::Base.instance.fetch(self)
      end
    end
  
    module InstanceMethods
      def save
        return context.save(self)
      end
    
      def delete
        return context.delete(self)
      end
    
      def context
        return self.class.context
      end
    end
  
  end
end