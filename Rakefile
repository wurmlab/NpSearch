require 'rake/testtask'

task default: [:build]

desc 'Builds and installs'
task install: [:build] do
  require_relative 'lib/npsearch/version'
  sh "gem install ./npsearch-#{NpSearch::VERSION}.gem"
end

desc 'Runs tests, generates documentation, builds gem (default)'
task build: [:test, :doc] do
  sh 'gem build npsearch.gemspec'
end

desc 'Runs tests'
task :test do
  Rake::TestTask.new do |t|
    t.libs.push 'lib'
    t.test_files = FileList['test/test_*.rb']
    t.verbose = true
  end
end
