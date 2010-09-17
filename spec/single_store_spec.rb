require File.join(File.dirname(__FILE__), 'spec_helper')

describe "SingleStore" do
  
  before(:all) do
    @klass_one = Class.new(Object)
  end
  
  
  it 'should find factories by multiple name formats' do
    @klass = Poro::ContextFactories::SingleStore::HashFactory
    
    [:hash, 'hash', 'HashFactory', 'HashContext', 'hash_context', :hash_context, @klass].each do |ident|
      factory = Poro::ContextFactories::SingleStore.instantiate(ident)
      factory.should be_kind_of(@klass), "Could not instantiate for #{ident.inspect}"
    end
  end
  
  it 'should supply the block' do
    block_called = false
    block_context = nil
    Poro::Context.factory = Poro::ContextFactories::SingleStore.instantiate(:hash) do |klass, context|
      klass.should == @klass_one
      context.should be_kind_of(Poro::Context)
      block_context = context
      block_called = true
    end
    
    @klass_one.send(:include, Poro::Persistify)
    returned_context = Poro::Context.fetch(@klass_one)
    block_called.should be_true
    returned_context.should == block_context
  end
  
  describe 'HashFactory' do
    
    it 'should supply a block with the klass and context' do
      block_called = false
      block_context = nil
      Poro::Context.factory = Poro::ContextFactories::SingleStore::HashFactory.new do |klass, context|
        klass.should == @klass_one
        context.should be_kind_of(Poro::Context)
        block_context = context
        block_called = true
      end
      
      @klass_one.send(:include, Poro::Persistify)
      returned_context = Poro::Context.fetch(@klass_one)
      block_called.should be_true
      returned_context.should == block_context
    end
    
  end
  
end