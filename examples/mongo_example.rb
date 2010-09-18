$LOAD_PATH.unshift('../lib')

require 'poro'
require 'mongo'
require 'digest/md5'

MongoDB = Mongo::Connection.new.db('poro-test')
puts MongoDB.collection_names.inspect

Poro::Context.factory = Poro::ContextFactories::SingleStore.instantiate(:mongo, :connection => MongoDB)

class Person
  include Poro::Persistify
  include Poro::Modelify
  
  def initialize(first_name, last_name)
    @first_name = first_name
    @last_name = last_name
    @created_at = Time.now
    @friends = []
    @pgs = [PG.new("group_#{Digest::MD5.hexdigest(first_name.to_s + last_name.to_s)[0,4]}"), 'none']
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


# Make one with the given ID and save it.  This will either insert or update.
jeff_id = BSON::ObjectId('4c913ec9b5915f5ef5000123')
mock_jeff = Person.new('Jeff', 'Mock')
mock_jeff.id = jeff_id
mock_jeff.save
puts "$$ mock_jeff = " + mock_jeff.inspect
puts "$$ fetched   = " + Person.fetch('4c913ec9b5915f5ef5000123').inspect

puts ''

# Create or get another record.  Make sure to put
ruben_monkey = nil
if( false )
  p = Person.new('Ruben', 'Monkey')
  p.friends = [mock_jeff]
  p.save
  ruben_monkey = p
else
  ruben_monkey_cursor = Person.context.data_store_cursor(:order => {:first_name => :desc}) {|o| puts '++' + o.inspect }
  puts "--\n" + ruben_monkey_cursor.to_a.inspect
  puts ''
  ruben_monkey_data = Person.context.find(:first, :conditions => {:first_name => 'Ruben', :last_name => 'Monkey'})
  ruben_monkey = Person.context.convert_to_plain_object(ruben_monkey_data)
end

puts "$$ ruben_monkey = " + ruben_monkey.inspect


# Insert one with no class_name and then fetch.
p_id = BSON::ObjectId('4c913ec9b5915f5ef5000555')
p_data = {'_id' => p_id, 'first_name' => 'Boo', 'last_name' => nil}
MongoDB[:people].save(p_data)

p = Person.fetch(p_id)
puts "$$ p = " + p.inspect