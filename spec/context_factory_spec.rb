require File.join(File.dirname(__FILE__), 'spec_helper')

describe "ContextManager" do
  
  before(:all) do
    @context_manager_klass = Poro::ContextFactory
    
    @klass_one = Class.new(Object)
    @klass_one.send(:include, Poro::Persistify)
    
    @klass_two = Class.new(String)
    @klass_two.send(:include, Poro::Persistify)
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
      if( klass == @klass_one )
        :alpha
      else
        :beta
      end
    end
    
    manager.fetch(@klass_one).should == :alpha
    manager.fetch(@klass_two).should == :beta
  end
  
  it 'should cache the fetched result' do
    manager = @context_manager_klass.new do |klass|
      o = Object.new
      o.instance_variable_set(:@klass, klass)
      o
    end
    
    context_one = manager.fetch(@klass_one)
    context_two = manager.fetch(@klass_two)
    
    manager.fetch(@klass_one).should == context_one
    manager.fetch(@klass_two).should_not == context_one
    manager.fetch(@klass_two).should == context_two
  end
  
  it 'should error when a class is not persistable' do
    manager = @context_manager_klass.new do |klass|
      Object.new
    end
    
    lambda {manager.fetch(@klass_one)}.should_not raise_error
    lambda {manager.fetch(Object)}.should raise_error(Poro::ContextFactory::FactoryError)
  end
  
end