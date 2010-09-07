require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Context" do
  
  before(:all) do
    @context_klass = Poro::Context
  end
  
  it 'should know its class' do
    context = @context_klass.new(Object)
    context.klass.should == Object
  end
  
  it 'should return self from a save' do
    context = @context_klass.new(Object)
    obj = Object.new
    context.save(obj).should == obj
  end
  
  it 'should return self from a remove' do
    context = @context_klass.new(Object)
    obj = Object.new
    context.remove(obj).should == obj
  end
  
  it 'should set the id on a save and unset it on remove' do
    obj = Object.new
    class << obj
      attr_reader :id
      attr_writer :id
    end
    
    obj.should respond_to(:id)
    obj.should respond_to(:id=)
    
    context = @context_klass.new(obj.class)
    
    obj.id.should == nil
    context.save(obj)
    obj.id.should_not == nil
    context.remove(obj)
    obj.id.should == nil
  end
  
  it 'should yield self at end of init' do
    block_context = nil
    context = @context_klass.new(Object) do |c|
      c.klass.should == Object
      block_context = c
    end
    context.should == block_context
  end
  
end