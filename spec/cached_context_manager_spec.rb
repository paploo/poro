puts File.join(File.dirname(__FILE__), 'spec_helper').inspect
require File.join(File.dirname(__FILE__), 'spec_helper')

describe "CachedContextManager" do
  
  before(:all) do
    @cached_context_manager_klass = Poro::ContextManagers::Cached
  end
  
  it 'should cache contexts' do
    manager = @cached_context_manager_klass.new do
      Object.new
    end
    
    object_context = manager.fetch(Object)
    string_context = manager.fetch(String)
    
    manager.fetch(Object).should == object_context
    manager.fetch(Object).should_not == string_context
    manager.fetch(String).should == string_context
  end
  
end