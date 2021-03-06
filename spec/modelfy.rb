require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Modelify" do
  
  before(:each) do
    class ModelifyTestContext
      def method_missing(method, *args, &block)
        return "#{method} called"
      end
      
      def primary_key
        return :id
      end
    end
    
    @standin_context = ModelifyTestContext.new
    
    Poro::ContextManager.instance = Poro::ContextManager.new do |klass|
      @standin_context
    end
    
    class ModelifyFoo
      include Poro::Modelify
    end
    
    @obj_klass = ModelifyFoo
    @obj = ModelifyFoo.new
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
  
  it 'should add id methods by default' do
    obj = @obj.dup
    
    obj.should respond_to(:id)
    obj.should respond_to(:id=)
    
    obj.id.should be_nil
    new_id = rand(10000)
    obj.id = new_id
    obj.id.should == new_id
  end
  
  it 'should respond_to find' do
    @obj_klass.should respond_to(:find)
  end
  
  it 'should respond_to data_store_find' do
    @obj_klass.should respond_to(:data_storefind)
  end
  
end