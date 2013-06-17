require "bundler/gem_tasks"

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'lib/fastbeans'
  t.test_files = FileList['test/*_test.rb']
  t.ruby_opts = ["-r./test/test_helper"]
  t.verbose = true
end

task :default => :test
