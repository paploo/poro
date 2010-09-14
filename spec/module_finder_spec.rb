require File.join(File.dirname(__FILE__), 'spec_helper')
require 'drb'

describe "Poro::Util::ModuleFinder" do
  
  before(:all) do
    @module_finder = Poro::Util::ModuleFinder
  end
  
  it 'should find simple classes' do
    @module_finder.find(String).should == String
    @module_finder.find(DRb::DRbError).should == DRb::DRbError
  end
  
  it 'should find a class from a string' do
    @module_finder.find("String").should == String
    @module_finder.find("DRb::DRbError").should == DRb::DRbError
  end
  
  it 'should find an absolute class from a string' do
    @module_finder.find("::String").should == ::String
    @module_finder.find("::DRb::DRbError").should == ::DRb::DRbError
  end
  
  it 'should find a class inside a root path' do
    @module_finder.find("DRbError", 'DRb').should == ::DRb::DRbError
    @module_finder.find("DRbError", DRb).should == ::DRb::DRbError
  end
  
  it 'should return a toplevel class like ruby if no inside one is found' do
    @module_finder.find("String", 'DRb').should == String
  end
  
  it 'should error if no class found inside when strict.' do
    lambda {@module_finder.find("String", 'DRb', true)}.should raise_error(NameError)
  end
  
  it 'should handle an empty string' do
    lambda {@module_finder.find('')}.should raise_error(NameError)
    lambda {@module_finder.find(' ')}.should raise_error(NameError)
    lambda {@module_finder.find("\t")}.should raise_error(NameError)
  end
  
  it 'should handle nil' do
    lambda {@module_finder.find(nil)}.should raise_error(NameError)
  end
    
  it 'should not run embedded code' do
    lambda {@module_finder.find('Object.new')}.should raise_error(NameError)
    lambda {@module_finder.find('raise RuntimeError')}.should raise_error(NameError)
  end
    
  it 'should handle garbage' do
    lambda {@module_finder.find('::::;cougar;#asdkjh*&(^&%^&')}.should raise_error(NameError)
  end
  
end