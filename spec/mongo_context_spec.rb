require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'MongoContext' do
  
  before(:each) do
    begin
      require 'mongo'
    rescue LoadError => e
      pending "Skip due to missing gem:  #{e.class}: #{e.message}"
    end
  end
  
  it "should have tests" do
    fail "No tests written"
  end
  
  describe 'Decoding' do
  
    it 'should not need class name on root object' do
      pending
    end
  
  end
  
  describe 'Encoding' do
  end
  
end