require 'rake'
require "rake/rdoctask"

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.rdoc_files.add "lib"
end

begin
  require "spec/rake/spectask"
  
  Spec::Rake::SpecTask.new(:spec) do |spec|
    spec.spec_opts = ['-c' '-f specdoc']
    spec.spec_files = ['spec']
  end
rescue LoadError
  task :spec do
    puts "You must have rspec installed to run this task."
  end
end