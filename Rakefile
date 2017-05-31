# frozen_string_literal: true

require 'rubocop/rake_task'
require 'rake/testtask'
require 'bundler/gem_tasks'

RuboCop::RakeTask.new
Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
end

task default: %i[test rubocop]
