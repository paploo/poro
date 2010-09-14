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
  
  describe 'Shortcut Configuration Method' do
    
    it 'should set the app instance' do
      @context_manager_klass.instance = @context_manager_klass.new() # Make sure we have one for testing.
      old_instance = @context_manager_klass.instance
      new_instance = @context_manager_klass.build_application_instance(Poro::Context)
      
      puts [old_instance, new_instance].inspect
      new_instance.should_not == old_instance
    end
    
    it 'should take a context class in multiple forms' do
      # There is no wat to know what was set, so I'm really just making sure it doesn't crash.
      lambda { @context_manager_klass.build_application_instance(Poro::Contexts::Hashed) }.should_not raise_error(NameError)
      lambda { @context_manager_klass.build_application_instance("Hashed") }.should_not raise_error(NameError)
      
      lambda { @context_manager_klass.build_application_instance("ThisDoesn'tExist")}.should raise_error(NameError)
    end
    
    it 'should not resolve a top-level module from the string' do
      lambda { @context_manager_klass.build_application_instance("String")}.should raise_error(NameError)
    end
    
    it 'should take a block that may or may not use the second argument' do
      @context_manager_klass.build_application_instance("Hashed") do |klass|
        klass.to_s + ' Alpha'
      end
      @context_manager_klass.instance.fetch(String).should == 'String Alpha'
      
      @context_manager_klass.build_application_instance("Hashed") do |klass, default_context|
        default_context.should == Poro::Contexts::Hashed
        klass.to_s + ' Beta'
      end
      @context_manager_klass.instance.fetch(String).should == 'String Beta'
    end
    
  end
  
end