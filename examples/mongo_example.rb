$LOAD_PATH.unshift('../lib')

require 'poro'
require 'mongo'

MongoDB = Mongo::Connection.new.db('poro-test')
puts MongoDB.collection_names.inspect

Poro::Context.factory = Poro::ContextFactory.new do |klass|
  collection_name = klass.to_s.gsub(/([a-z0-9])([A-Z])/, '\1_\2').downcase
  context = Poro::Contexts::MongoContext.new(klass)
  context.data_store = MongoDB[collection_name]
  context
end

class Person
  include Poro::Persistify
  include Poro::Modelify
  
  def initialize(first_name, last_name)
    @first_name = first_name
    @last_name = last_name
    @created_at = Time.now
    #@birthdate = nil
    #@in_system = true
    #@friends = []
    #@heads_of_cattle = rand(1000)
    @pgs = [PG.new('none')]
  end
  
  attr_reader :first_name, :last_name, :birthdate, :in_system, :friends
  attr_writer :first_name, :last_name, :birthdate, :in_system, :friends
end

class PG
  
  def initialize(name)
    @name = name
  end
  
  attr_reader :name
  
end

jeff_id = BSON::ObjectId('4c913ec9b5915f5ef5000123')
mock_jeff = Person.new('Jeff', 'Mock')
mock_jeff.id = jeff_id
mock_jeff.save
puts "@@ mock_jeff = " + mock_jeff.inspect

puts ''

# Create or get
ruben_monkey = nil
if( false )
  p = Person.new('Ruben', 'Monkey')
  p.friends = [mock_jeff]
  p.save
  ruben_monkey = p
else
  ruben_monkey_data = Person.context.data_store.find_one({:first_name => 'Ruben', :last_name => 'Monkey'})
  ruben_monkey = Person.context.convert_to_plain_object(ruben_monkey_data)
end

puts "@@ ruben_monkey = " + ruben_monkey.inspect

puts [__FILE__, __LINE__, BSON::OrderedHash.new.kind_of?(Hash)].inspect