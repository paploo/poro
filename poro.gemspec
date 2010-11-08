# Rake require fancy footwork is for bundler's benefit.
begin
  Rake
rescue NameError
  require 'rake'
end

require File.join( File.dirname(__FILE__), 'lib', 'poro', 'version' )

Gem::Specification.new do |s|
  s.name = 'poro'
  s.version = Poro::VERSION
  
  s.required_ruby_version = '>= 1.9.2'
  
  s.authors = ['Jeff Reinecke']
  s.email = 'jeff@paploo.net'
  s.homepage = 'http://www.github.com/paploo/poro'
  
  s.require_paths = ['lib']
  s.licenses = ['BSD']
  s.files = FileList['README.rdoc', 'LICENSE.txt', 'Rakefile', 'lib/**/*', 'spec/**/*']
  
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc']
  
  s.summary = "Persistence of Plain Ol' Ruby Objects in MongoDB, Memory, and eventually SQL and Memcache."
  s.description = <<-DESC
    Plain Ol' Ruby Objects (PORO) is a persistence engine that can use nearly
    any persistence store.  Its purpose is to allow you to easily add a
    persistence store to your existing objects in an application.  Currently,
    there is support for MongoDB, though SQL and Memcache support is planned.
  DESC
end