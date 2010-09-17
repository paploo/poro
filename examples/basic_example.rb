$LOAD_PATH.unshift('../lib') # This step is unecessary if loading from a gem.

require 'poro'

Poro::Context.factory = Poro::ContextFactories::SingleStore.instantiate(:hash)

class Foo
  include Poro::Persistify
  include Poro::Modelify
end

f = Foo.new
puts "f doesn't have an ID yet: #{f.id.inspect}"
f.save
puts "f now has an ID: #{f.id.inspect}"
g = Foo.fetch(f.id)
puts "g is a fetch of f and has the same ID as f: #{g.id.inspect}"
f.remove
puts "f no longer has an ID: #{f.id.inspect}"