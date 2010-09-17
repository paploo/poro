require File.join(File.dirname(__FILE__), 'spec_helper')

describe "HashContext" do
  
  before(:each) do
    @obj = Object.new
    class << @obj
      attr_reader :id
      attr_writer :id
    end
    
    @context = Poro::Contexts::HashContext.new(@obj.class)
  end
  
  it "should have a hash for a data store" do
    @context.data_store.should be_kind_of(Hash)
  end
  
  it "should save and fetch a new item" do
    @obj.id.should be_nil
    @context.save(@obj)
    @obj.id.should_not be_nil
    
    fetched_obj = @context.fetch(@obj.id)
    fetched_obj.should == @obj
  end
  
  it "should update an existing item" do
    # Assume saving a new object works fir this test (there is another test save on new)
    @context.save(@obj)
    id_1 = @obj.id
    id_1.should_not be_nil
    
    @context.save(@obj)
    id_2 = @obj.id
    id_2.should == id_1
  end
  
  it "should remove an item" do
    @context.save(@obj)
    
    obj_id = @obj.id
    obj_id.should_not be_nil
    
    fetched_obj = @context.fetch(obj_id)
    fetched_obj.should_not be_nil
    
    @context.remove(@obj)
    
    new_obj_id = @obj.id
    new_obj_id.should be_nil
    
    refetched_obj = @context.fetch(obj_id)
    refetched_obj.should be_nil
  end
  
  it "should error when trying to save an object that can't handle IDs" do
    o = Object.new
    o.should_not respond_to(:id)
    o.should_not respond_to(:id=)
    
    lambda {@context.save(o)}.should raise_error(Poro::Context::SaveError)
  end
  
  it "should error when trying to remove an object that can't handle IDs" do
    o = Object.new
    o.should_not respond_to(:id)
    o.should_not respond_to(:id=)
    
    lambda {@context.remove(o)}.should raise_error(Poro::Context::RemoveError)
  end
  
end