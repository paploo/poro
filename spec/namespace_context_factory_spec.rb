require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Namespace Context Factory" do
  
  it 'should register and fetch a default factory' do
    default_factory = :default_factory
    
    factory = Poro::ContextFactories::NamespaceFactory.new(default_factory)
    factory.fetch_factory.should == default_factory
  end
  
  it 'should register and fetch a namespaced factory' do
    default_factory = :default_factory
    foo_factory = :foo_factory
    
    factory = Poro::ContextFactories::NamespaceFactory.new(default_factory)
    factory.register_factory(foo_factory, "Foo")
    
    factory.fetch_factory.should == default_factory
    factory.fetch_factory("Foo").should == foo_factory
  end
  
  it 'should get the nearest matching factory' do
    default_factory = :default_factory
    foo_factory = :foo_factory
    bar_factory = :bar_factory
    chocolate_factory = :chocolate_factory
    
    factory = Poro::ContextFactories::NamespaceFactory.new(default_factory)
    factory.register_factory(foo_factory, "Foo")
    factory.register_factory(bar_factory, "Foo::Bar")
    factory.register_factory(chocolate_factory, "Candy::Chocolate")
    
    factory.fetch_factory.should == default_factory
    
    factory.fetch_factory("Foo").should == foo_factory
    factory.fetch_factory("Foo::Bar").should == bar_factory
    factory.fetch_factory("Foo::Bar::Baz").should == bar_factory
    factory.fetch_factory("Foo::Fiz").should == foo_factory
    
    factory.fetch_factory("Chocolate").should == default_factory
    factory.fetch_factory("Candy::Chocolate").should == chocolate_factory
    factory.fetch_factory("Candy::Chocolate::Dark").should == chocolate_factory
    factory.fetch_factory("Candy").should == default_factory
  end
  
  it 'should fetch a context' do
    @klass_1 = Class.new(Object)
    @klass_1.send(:include, Poro::Persistify)
    @klass_2 = Class.new(Object)
    @klass_2.send(:include, Poro::Persistify)
    ::PoroNamespacedContextFactoryTestFetchOne = @klass_1
    ::PoroNamespacedContextFactoryTestFetcgTwo = @klass_2
    
    @klass_1.name.should_not == @klass_2.name
    
    default_factory = Poro::ContextFactory.new {|klass| "default #{klass.name}"}
    foo_factory = Poro::ContextFactory.new {|klass| "foo #{klass.name}"}
    
    factory = Poro::ContextFactories::NamespaceFactory.new(default_factory)
    factory.register_factory(foo_factory, @klass_2.name)
    
    context = factory.fetch(@klass_1)
    context.should == "default #{@klass_1.name}"
    
    context = factory.fetch(@klass_2)
    context.should == "foo #{@klass_2.name}"
  end
  
  it 'should take a configuration block' do
    @klass_1 = Class.new(Object)
    @klass_1.send(:include, Poro::Persistify)
    @klass_2 = Class.new(Object)
    @klass_2.send(:include, Poro::Persistify)
    ::PoroNamespacedContextFactoryTestBlockOne = @klass_1
    ::PoroNamespacedContextFactoryTestBlockTwo = @klass_2
    
    @klass_1.name.should_not == @klass_2.name
    
    default_factory = Poro::ContextFactory.new {|klass| "default #{klass.name}"}
    foo_factory = Poro::ContextFactory.new {|klass| "foo #{klass.name}"}
    
    factory = Poro::ContextFactories::NamespaceFactory.new(default_factory) do |f|
      f.register_factory(foo_factory, @klass_2.name)
    end
    
    context = factory.fetch(@klass_1)
    context.should == "default #{@klass_1.name}"
    
    context = factory.fetch(@klass_2)
    context.should == "foo #{@klass_2.name}"
  end
  
end