require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new( :spec )

task default: :spec

desc 'Build the gem'
task :build do
  system 'gem build sapis.gemspec'
end

desc 'Install the gem locally'
task :install => :build do
  system 'gem install sapis-0.1.0.gem'
end

desc 'Clean build artifacts'
task :clean do
  system 'rm -f *.gem'
end
