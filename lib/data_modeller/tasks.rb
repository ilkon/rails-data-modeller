# frozen_string_literal: true

require_relative 'tasks/string_boolean'

namespace :data_modeller do
  Dir["#{File.dirname(__FILE__)}/tasks/**/*.rake"].each { |ext| load(ext) }
end
