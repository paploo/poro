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
  
end