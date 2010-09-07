require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Context" do
  
  before(:each) do
    @standin_context = :foo
    
    Poro::ContextManager::Base.instance = Poro::ContextManager::Base.new do |klass|
      @standin_context
    end
    
    class Foo
      include Poro::Persistify
    end
    
    @obj_klass = Foo
    @obj = Foo.new
  end
  
  it 'should include class methods' do
    @obj_klass.should respond_to(:find)
  end
  
  it 'should include instance methods' do
    @obj.should respond_to(:save)
  end
  
  it 'should reference the context' do
    @obj_klass.context.should == @standin_context
    @obj.context.should == @standin_context
  end
  
  it 'should pass-through find' do
    pending
  end
  
  it 'should pass-through save' do 
    pending
  end
  
  it 'should pass-through delete' do
    pending
  end
  
end