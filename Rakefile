require 'bundler/gem_tasks'
require 'rake/testtask'

task default: [:build]
desc 'Installs the ruby gem'
task :build do
  exec("gem build np_search.gemspec && gem install ./NpSearch-#{NpSearch::VERSION}.gem")
end

task :test do
  Rake::TestTask.new do |t|
    t.pattern = 'test/test_np_search.rb'
  end
end
