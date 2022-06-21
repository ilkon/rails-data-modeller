# frozen_string_literal: true

require 'rake'
require 'rake/testtask'
require 'rdoc/task'

RAILS_ROOT = File.dirname(__FILE__)

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'data_modeller'

::DataModeller::Config.setup_logger

require 'data_modeller/tasks'

# Add task aliases for convenience
Rake::Task.tasks.select { |t| t.name.start_with?('data_modeller:') }.each do |t|
  desc t.comment if t.comment
  task t.name.sub('data_modeller:', '') => t.name
end

desc 'Open an irb session preloaded with this library'
task :console do
  sh "RAILS_ROOT='#{File.dirname(__FILE__)}' irb -I lib -r data_modeller"
end
