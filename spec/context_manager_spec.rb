require File.join(File.dirname(__FILE__), 'spec_helper')

describe "ContextManager" do
  
  before(:all) do
    @context_manager_klass = Poro::ContextManager
  end
  
  it 'should save the context instance' do
    @context_manager_klass.instance.should == nil
    testObject = Object.new
    @context_manager_klass.instance = testObject
    @context_manager_klass.instance.should == testObject
  end
  
  it 'should run the context block on fetch' do
    manager = @context_manager_klass.new do |klass|
      if( klass == String )
        :alpha
      else
        :beta
      end
    end
    
    manager.fetch(String).should == :alpha
    manager.fetch(Object).should == :beta
  end
  
  it 'should not cache the fetched result' do
    manager = @context_manager_klass.new do
      Object.new
    end
    
    object_context = manager.fetch(Object)
    string_context = manager.fetch(String)
    
    manager.fetch(Object).should_not == object_context
    manager.fetch(Object).should_not == string_context
    manager.fetch(String).should_not == string_context
  end
  
end