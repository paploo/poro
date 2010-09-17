require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Context" do
  
  before(:all) do
    @context_klass = Poro::Context
    
    @klass_one = Class.new(Object)
  end
  
  it 'should know its class' do
    context = @context_klass.new(Object)
    context.klass.should == Object
  end
  
  it 'should have an immutable class' do
    context = @context_klass.new(Object)
    context.should_not respond_to(:klass=)
  end
  
  it 'should return its data store' do
    context = @context_klass.new(Object)
    context.should respond_to(:data_store)
  end
   
  it 'should have an immutable data store' do
   context = @context_klass.new(Object)
   context.should_not respond_to(:dat_store=)
  end
  
  it 'should return the saved object from a save' do
    context = @context_klass.new(Object)
    obj = Object.new
    context.save(obj).should == obj
  end
  
  it 'should return the removed object from a remove' do
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
  
  it 'should have a customizable id method' do
    obj = Object.new
    class << obj
      attr_reader :pk
      attr_writer :pk
    end
    
    context = @context_klass.new(obj.class)
    context.primary_key = :pk
    
    obj.pk.should be_nil
    context.primary_key_value(obj).should == obj.pk
    context.set_primary_key_value(obj, 12345)
    obj.pk.should == 12345
    context.primary_key_value(obj).should == obj.pk
  end
  
  it 'should yield self at end of initialization' do
    block_context = nil
    context = @context_klass.new(Object) do |c|
      c.klass.should == Object
      block_context = c
    end
    context.should == block_context
  end
  
  it 'should be able to fetch the context for a class' do
    x = rand(1000)
    Poro::ContextFactory.instance = Poro::ContextFactory.new do |klass|
      "#{klass}, #{x}"
    end
    
    @klass_one.send(:include, Poro::Persistify)
    
    Poro::Context.fetch(@klass_one).should == "#{@klass_one}, #{x}"
  end
  
  it 'should be able to fetch the context for an object' do
    x = rand(1000)
    Poro::ContextFactory.instance = Poro::ContextFactory.new do |klass|
      "#{klass}, #{x}"
    end
    
    @klass_one.send(:include, Poro::Persistify)
    
    Poro::Context.fetch(@klass_one.new).should == "#{@klass_one}, #{x}"
  end
  
end