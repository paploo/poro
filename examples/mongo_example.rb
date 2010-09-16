$LOAD_PATH.unshift('../lib')
require 'poro'
require 'mongo'

MongoDB = Mongo::Connection.new.db('poro-test')

Poro::Context.factory = Poro::ContextFactory.new do |klass|
  collection_name = klass.to_s.gsub(/([a-z0-9])([A-Z])/, '\1_\2').downcase
  context = Poro::Contexts::Mongo.new(klass)
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
    #@pgs = [PG.new('none')]
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

jeff_id = BSON::ObjectID('4c913ec9b5915f5ef5000123')
mock_jeff = Person.new('Jeff', 'Mock')
mock_jeff.id = jeff_id
puts mock_jeff.inspect
mock_jeff.save

p = Person.new('Ruben', 'Monkey')
p.friends = [mock_jeff]
p.save
puts p.inspect
puts p.id.inspect