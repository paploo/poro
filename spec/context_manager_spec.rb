require File.join(File.dirname(__FILE__), 'spec_helper')

describe "ContextManager" do
  
  before(:all) do
    @context_manager_klass = Poro::ContextManager
  end
  
  it 'should save the context instance' do
    testObject = @context_manager_klass.new
    @context_manager_klass.instance = testObject
    @context_manager_klass.instance.should == testObject
  end
  
  it 'should error if the application context manager is set to an inappropriate object kind' do
    lambda {@context_manager_klass.instance = :foo}.should raise_error
    lambda {@context_manager_klass.instance = nil}.should_not raise_error
  end
  
  it 'should error if the application context manager is unset' do
    @context_manager_klass.instance = nil
    lambda {@context_manager_klass.instance}.should raise_error
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
  
  it 'should not cache the fetched result (only subclasses should if they want to)' do
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