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
    
    lambda {@context.save(o)}.should raise_error
  end
  
  it "should error when trying to remove an object that can't handle IDs" do
    o = Object.new
    o.should_not respond_to(:id)
    o.should_not respond_to(:id=)
    
    lambda {@context.remove(o)}.should raise_error
  end
  
  describe "Finding" do
    
    before(:each) do
      
      class HashContextPerson
        include Poro::Persistify
        def initialize(id, first_name, last_name, friends=[])
          @id = id
          @first_name = first_name
          @last_name = last_name
          @friends = friends
        end
        
        attr_reader :id
        attr_writer :id
      end
      
      george_smith = HashContextPerson.new(1, 'George', 'Smith')
      george_archer = HashContextPerson.new(2, 'George', 'Archer', [george_smith])
      bridgette_smith = HashContextPerson.new(3, 'Bridgette', 'Smith')
      karen_zeta = HashContextPerson.new(4, 'Karen', 'Zeta', [george_archer, george_smith])
      @data = [
        george_smith,
        george_archer,
        bridgette_smith,
        karen_zeta
      ]
      
      @context = Poro::Contexts::HashContext.new(HashContextPerson)
      @data.each {|person| @context.save(person)}
    end
    
    it 'should get shallow values' do
      expected_first_names = ['George', 'George', 'Bridgette', 'Karen']
      first_names_sym = @data.map {|record| @context.send(:value_for_key, record, :first_name)[:value]}
      first_names_str = @data.map {|record| @context.send(:value_for_key, record, 'first_name')[:value]}
      first_names_sym.should == first_names_str
      first_names_sym.should == expected_first_names
      
      expected_ids = [1, 2, 3, 4]
      ids_sym = @data.map {|record| @context.send(:value_for_key, record, :id)[:value]}
      ids_str = @data.map {|record| @context.send(:value_for_key, record, 'id')[:value]}
      ids_sym.should == ids_str
      ids_sym.should == expected_ids
    end
    
    it 'should get embedded' do
      expected_values = [{:found=>false, :value=>nil}, {:found=>true, :value=>1}, {:found=>false, :value=>nil}, {:found=>true, :value=>2}]
      values = @data.map {|record| @context.send(:value_for_key, record, 'friends.0.id')}
      values.should == expected_values
    end
    
    it 'should sort' do
      order_opt = {:first_name => :asc}
      expected_values = [3,1,2,4]
      values = @context.send(:sort, @data, order_opt).map {|record| @context.send(:value_for_key, record, :id)[:value]}
      values.should == expected_values
      
      order_opt = {:first_name => :asc, :last_name => :asc}
      expected_values = [3,2,1,4]
      values = @context.send(:sort, @data, order_opt).map {|record| @context.send(:value_for_key, record, :id)[:value]}
      values.should == expected_values
      
      order_opt = {:first_name => :asc, :last_name => :desc}
      expected_values = [3,1,2,4]
      values = @context.send(:sort, @data, order_opt).map {|record| @context.send(:value_for_key, record, :id)[:value]}
      values.should == expected_values
      
      order_opt = {:last_name => :asc, :first_name => :asc}
      expected_values = [2,3,1,4]
      values = @context.send(:sort, @data, order_opt).map {|record| @context.send(:value_for_key, record, :id)[:value]}
      values.should == expected_values
      
      order_opt = {'friends.0.id' => :asc, 'last_name' => :desc, 'first_name' => :desc}
      expected_values = [1,3,2,4]
      values = @context.send(:sort, @data, order_opt).map {|record| @context.send(:value_for_key, record, :id)[:value]}
      values.should == expected_values
    end
    
    it 'should filter' do
      filter_opt = {:last_name => 'Smith'}
      expected_values = [1,3]
      values = @context.send(:filter, @data, filter_opt).map {|record| @context.send(:value_for_key, record, :id)[:value]}
      values.should == expected_values
      
      filter_opt = {'first_name' => 'George'}
      expected_values = [1,2]
      values = @context.send(:filter, @data, filter_opt).map {|record| @context.send(:value_for_key, record, :id)[:value]}
      values.should == expected_values
      
      filter_opt = {:first_name => 'George', 'last_name' => 'Smith'}
      expected_values = [1]
      values = @context.send(:filter, @data, filter_opt).map {|record| @context.send(:value_for_key, record, :id)[:value]}
      values.should == expected_values
      
      filter_opt = {'friends.0.id' => nil}
      expected_values = []
      values = @context.send(:filter, @data, filter_opt).map {|record| @context.send(:value_for_key, record, :id)[:value]}
      values.should == expected_values
      
      filter_opt = {'friends.0.id' => 2}
      expected_values = [4]
      values = @context.send(:filter, @data, filter_opt).map {|record| @context.send(:value_for_key, record, :id)[:value]}
      values.should == expected_values
    end
    
    it 'should limit' do
      limit_opt = {:limit => nil, :offset => 0}
      expected_values = [1,2,3,4]
      values = @context.send(:limit, @data, limit_opt).map {|record| @context.send(:value_for_key, record, :id)[:value]}
      values.should == expected_values
      
      limit_opt = {:limit => 2, :offset => 0}
      expected_values = [1,2]
      values = @context.send(:limit, @data, limit_opt).map {|record| @context.send(:value_for_key, record, :id)[:value]}
      values.should == expected_values
      
      limit_opt = {:limit => 2, :offset => 3}
      expected_values = [4]
      values = @context.send(:limit, @data, limit_opt).map {|record| @context.send(:value_for_key, record, :id)[:value]}
      values.should == expected_values
      
      limit_opt = {:limit => 100, :offset => 2}
      expected_values = [3,4]
      values = @context.send(:limit, @data, limit_opt).map {|record| @context.send(:value_for_key, record, :id)[:value]}
      values.should == expected_values
      
      limit_opt = {:limit => nil, :offset => 2}
      expected_values = [3,4]
      values = @context.send(:limit, @data, limit_opt).map {|record| @context.send(:value_for_key, record, :id)[:value]}
      values.should == expected_values
      
      limit_opt = {:limit => nil, :offset => 100}
      expected_values = []
      values = @context.send(:limit, @data, limit_opt).map {|record| @context.send(:value_for_key, record, :id)[:value]}
      values.should == expected_values
    end
    
    it 'should find all' do
      opts = {:conditions => {:last_name => 'Smith'}, :order => :first_name}
      expected_values = [3,1]
      values = @context.find(:all, opts).map {|record| @context.send(:value_for_key, record, :id)[:value]}
      values.should == expected_values
      
      values = @context.find(:many, opts).map {|record| @context.send(:value_for_key, record, :id)[:value]}
      values.should == expected_values
    end
    
    it 'should find first' do
      opts = {:conditions => {:last_name => 'Smith'}, :order => :first_name}
      record = @context.find(:first, opts)
      @context.send(:value_for_key, record, :id)[:value].should == 3
      
      record = @context.find(:one, opts)
      @context.send(:value_for_key, record, :id)[:value].should == 3
    end
    
  end
  
end