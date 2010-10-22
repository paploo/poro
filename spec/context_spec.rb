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
  
  describe 'Callbakcs' do
    
    before(:each) do
      @context = @context_klass.new(@klass_one)
    end
    
    it 'should allow direct inspection of callbacks' do
      bs_callbacks = @context.callbacks(:before_save)
      bs_callbacks.should be_kind_of(Array)
      
      as_callbacks = @context.callbacks(:after_save)
      as_callbacks.should be_kind_of(Array)
      
      as_callbacks.object_id.should_not == bs_callbacks.object_id
      @context.callbacks(:before_save).object_id.should == bs_callbacks.object_id
    end
    
    it 'should allow callback registration' do
      @context.callbacks(:before_save).should be_empty
      @context.register_callback(:before_save) {|obj| obj}
      @context.callbacks(:before_save).length.should == 1
      
      @context.register_callback(:after_save) {|obj| obj}
      @context.callbacks(:after_save).length.should == 1
      
      @context.callbacks(:before_save).length.should == 1
    end
    
    it 'should clear callbacks' do
      @context.register_callback(:before_save) {|obj| obj}
      @context.callbacks(:before_save).length.should == 1
      @context.clear_callbacks(:before_save)
      @context.callbacks(:before_save).should be_empty
    end
    
    it 'should have private firing methods' do
      @context.private_methods.should include(:callback_event)
      @context.private_methods.should include(:callback_transform)
      @context.private_methods.should include(:callback_filter?)
    end
    
    it 'should call event callbacks' do
      @context.register_callback(:before_save) {|obj| obj[:foo] = 'bar'}
      @context.register_callback(:before_save) {|obj| obj[:alpha] = 'beta'}
      @context.register_callback(:after_save) {|obj| obj[:p] = 'q'}
      
      some_object = {:foo => 'untouched', :value => 12345}
      result = @context.send(:callback_event, :before_save, some_object)
      result.object_id.should == some_object.object_id
      some_object.should == {:foo => 'bar', :value => 12345, :alpha => 'beta'}
    end
    
    it 'should handle transform callbacks' do
      @context.register_callback(:before_save) {|obj| obj.merge(:foo => 'bar')}
      @context.register_callback(:before_save) {|obj| obj.merge(:alpha => 'beta').to_a}
      @context.register_callback(:after_save) {|obj| 'q'}
      
      some_object = {:foo => 'untouched', :value => 12345}
      result = @context.send(:callback_transform, :before_save, some_object)
      result.should == [[:foo, 'bar'], [:value, 12345], [:alpha, 'beta']]
      some_object.should == {:foo => 'untouched', :value => 12345}
    end
    
    it 'should handle no transform callbacks' do
      @context.callbacks(:before_save).should be_empty
      
      some_object = {:foo => 'untouched', :value => 12345}
      result = @context.send(:callback_transform, :before_save, some_object)
      result.object_id.should == some_object.object_id
    end
    
    it 'should handle filter callbacks' do
      @context.register_callback(:should_save?) {|obj| obj[:foo] = 'bar'; nil}
      @context.register_callback(:should_save?) {|obj| obj[:alpha] = 'beta'; obj}
      @context.register_callback(:should_remove?) {|obj| obj[:p] = 'q'; :done}
      
      # Make sure it cancels properly.
      some_object = {:foo => 'untouched', :value => 12345}
      result = @context.send(:callback_filter?, :should_save?, some_object)
      result.should be_nil
      some_object.should == {:foo => 'bar', :value => 12345}
      
      # Make sure it still runs properly, even if the default is false.
      some_object = {:foo => 'untouched', :value => 12345}
      result = @context.send(:callback_filter?, :should_save?, some_object, false)
      result.should be_nil
      some_object.should == {:foo => 'bar', :value => 12345}
      
      # Make sure it falls off the end correctly.
      some_object = {:foo => 'untouched', :value => 12345}
      result = @context.send(:callback_filter?, :should_remove?, some_object)
      result.should == :done
      some_object.should == {:foo => 'untouched', :value => 12345, :p => 'q'}
    end
    
    it 'should handle no filter callbacks' do
      @context.callbacks(:save_should?).should be_empty
       
       # Make sure it defaults to true when there are no callbacks.
      some_object = {:foo => 'untouched', :value => 12345}
      result = @context.send(:callback_filter?, :should_save?, some_object)
      result.should == true
      some_object.should == {:foo => 'untouched', :value => 12345}
      
      # Make sure it uses the passed default when there are no callbacks.
      some_object = {:foo => 'untouched', :value => 12345}
      result = @context.send(:callback_filter?, :should_save?, some_object, :some_default)
      result.should == :some_default
      some_object.should == {:foo => 'untouched', :value => 12345}
    end
    
  end
  
  describe 'FindHelpers' do
    
   it 'should have base methods private' do
     pending
   end
   
   it 'should pass calls from the main two public methods to their underlying private methods based on argument' do
     pending
   end
    
  end
  
end