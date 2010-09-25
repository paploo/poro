require 'rake'

Gem::Specification.new do |s|
  s.name = 'poro'
  s.version = '0.2.0'
  
  s.required_ruby_version = '>= 1.9.2'
  
  s.authors = ['Jeff Reinecke']
  s.email = 'jeff@paploo.net'
  s.homepage = 'http://www.github.com/paploo/poro'
  
  s.require_paths = ['lib']
  s.licenses = ['BSD']
  s.files = FileList['README.rdoc', 'LICENSE.txt', 'Rakefile', 'lib/**/*', 'spec/**/*']
  
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc']
  
  s.summary = 'A lightweight thin persistence engine that can utilize many different persistence data stores.'
  s.description = <<-DESC
    Plain Ol' Ruby Objects (PORO) is a thing and lightweight persistence engine
    that can use nearly any persistence store.  Its purpose is to allow you to
    easily add a persistence store to your existing objects in an application.
  DESC
end