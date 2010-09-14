require 'rake'
require "rake/rdoctask"

# ===== RDOC BUILDING =====
# This isn't necessary if installing from a gem.

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.rdoc_files.add "lib/**/*.rb", "README.rdoc"
end

# ===== SPEC TESTING =====

begin
  require "spec/rake/spectask"
  
  Spec::Rake::SpecTask.new(:spec) do |spec|
    spec.spec_opts = ['-c' '-f specdoc']
    spec.spec_files = ['spec']
  end
  
  Spec::Rake::SpecTask.new(:spec_with_backtrace) do |spec|
    spec.spec_opts = ['-c' '-f specdoc', '-b']
    spec.spec_files = ['spec']
  end
rescue LoadError
  task :spec do
    puts "You must have rspec installed to run this task."
  end
end

# ===== GEM BUILDING =====

desc "Build the gem file for this package"
task :build_gem do
  STDOUT.puts `gem build poro.gemspec`
end