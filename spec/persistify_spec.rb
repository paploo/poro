require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Persistify" do
  
  before(:each) do
    class PersistifyTestContext
      def method_missing(method, *args, &block)
        return "#{method} called"
      end
    end
    
    @standin_context = PersistifyTestContext.new
    
    Poro::ContextManager.instance = Poro::ContextManager.new do |klass|
      @standin_context
    end
    
    class PersistifyFoo
      include Poro::Persistify
    end
    
    @obj_klass = PersistifyFoo
    @obj = PersistifyFoo.new
  end
  
  it 'should include class methods' do
    @obj_klass.should respond_to(:fetch)
  end
  
  it 'should include instance methods' do
    @obj.should respond_to(:save)
  end
  
  it 'should reference the context' do
    @obj_klass.context.should == @standin_context
    @obj.context.should == @standin_context
  end
  
  it 'should pass-through find' do
    @obj_klass.fetch(3).should == "fetch called"
  end
  
  it 'should pass-through save' do 
    @obj.save.should == "save called"
  end
  
  it 'should pass-through remove' do
    @obj.remove.should == "remove called"
  end
  
end