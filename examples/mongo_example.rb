$LOAD_PATH.unshift('../lib')
require 'poro'
require 'mongo'

MongoDB = Mongo::Connection.new.db('poro-test')

Poro::ContextManager.instance = Poro::ContextManagers::Cached.new do |klass|
  return nil unless klass.include?(Poro::Persistify)
  collection_name = klass.to_s.gsub(/([a-z0-9])([A-Z])/, '\1_\2').downcase
  Poro::Contexts::Mongo.new(klass, MongoDB[collection_name])
end

class Person
  # This could be done for inline configuration before persistifying, but
  # how to tell the configuration block on the manager that this is a good idea.
  #Poro::Context.configure_for_class(Person) do
  #end
  include Poro::Persistify
  
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