# frozen_string_literal: true

require_relative 'generators/base'
Dir["#{File.dirname(__FILE__)}/generators/**/*.rb"].each { |ext| require(ext) }
