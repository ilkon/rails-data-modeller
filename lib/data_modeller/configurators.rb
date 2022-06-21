# frozen_string_literal: true

require 'yaml'

Dir["#{File.dirname(__FILE__)}/configurators/**/*.rb"].each { |ext| require(ext) }
