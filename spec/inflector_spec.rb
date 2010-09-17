require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'Inflector' do
  
  before(:all) do
    @inflector = Poro::Util::Inflector
  end
  
  it 'should camelize' do
    @inflector.camelize('some_underscored_thing').should == "SomeUnderscoredThing"
  end
  
  it 'should underscore' do
    @inflector.underscore('SomeCamelizedThing').should == "some_camelized_thing"
  end
  
  it 'should pluralize' do
    @inflector.pluralize('person').should == 'people'
  end
  
  it 'should singularize' do
    @inflector.singularize('people').should == 'person'
  end
  
  it 'should not include itself into string' do
    "Foo".should_not respond_to(:underscore)
    "Foo".should_not respond_to(:camelize)
    "Foo".should_not respond_to(:pluralize)
    "Foo".should_not respond_to(:singularize)
  end
  
end