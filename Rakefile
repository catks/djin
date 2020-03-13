require "bundler/gem_tasks"
require "rspec/core/rake_task"
require_relative "lib/djin"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

desc 'Djin REPL'
task :console do
  require 'irb'
  ARGV.clear
  IRB.start
end
