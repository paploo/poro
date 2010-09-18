$LOAD_PATH.unshift('../lib')

require 'poro'
require 'mongo'
require 'digest/md5'

# Setup the mongo connection.
MongoDB = Mongo::Connection.new.db('poro-test')

# Setup the application's factory.
Poro::Context.factory = Poro::ContextFactories::SingleStore.instantiate(:mongo, :connection => MongoDB)

# Define the class Person.
class Person
  include Poro::Persistify
  include Poro::Modelify
  
  def initialize(first_name, last_name)
    @first_name = first_name
    @last_name = last_name
    @created_at = Time.now
    @friends = []
    @tags = [Tag.new("group_#{Digest::MD5.hexdigest(first_name.to_s + last_name.to_s)[0,4]}"), 'none']
  end
  
  attr_reader :first_name, :last_name, :birthdate, :in_system, :friends
  attr_writer :first_name, :last_name, :birthdate, :in_system, :friends
end

# Define a tag class.
class Tag
  
  def initialize(name)
    @name = name
  end
  
  attr_reader :name
  
end


# Make one with the given ID and save it.  This will either insert or update.
puts "** Make a record and force an ID into it before saving it.  This will either create it or update it."
jeff_id = BSON::ObjectId('4c913ec9b5915f5ef5000123')
jeff = Person.new('Jeff', 'Reinecke')
jeff.id = jeff_id
jeff.save
puts "$$ jeff obj     = " + jeff.inspect
puts "$$ fetched jeff = " + Person.fetch('4c913ec9b5915f5ef5000123').inspect

puts ''

# Create or get another record.  Make sure to put
ruben_monkey = Person.find(:first, :conditions => {:first_name => 'Ruben', :last_name => 'Monkey'})
if( ruben_monkey.nil? )
  puts "** Make Ruben Monkey"
  ruben_monkey = Person.new('Ruben', 'Monkey')
  ruben_monkey.friends = [mock_jeff]
  ruben_monkey.save
else
  puts "** Show Off Cursors"
  ruben_monkey_cursor = Person.context.data_store_cursor(:order => {:first_name => :desc}) {|o| puts '++Cursor Block: ' + o.inspect }
end

puts ''
puts "$$ ruben_monkey = " + ruben_monkey.inspect


# Insert a raw record with no class_name and then fetch it to make sure decoding works even with no class name attributes.
puts ''
puts "** Force in a record and make sure it doesn't need a class name attributes if is a root document."
boo_id = BSON::ObjectId('4c913ec9b5915f5ef5000555')
boo_data = {'_id' => boo_id, 'first_name' => 'Boo', 'last_name' => nil}
MongoDB[:people].save(boo_data)

boo = Person.fetch(boo_id)
puts "$$ boo = " + boo.inspect