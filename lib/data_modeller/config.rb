# frozen_string_literal: true

require 'logger'

module DataModeller
  class Config
    class << self
      def setup_logger
        self.logger = Logger.new($stdout).tap do |logger|
          logger.level = ENV['DEBUG'] ? Logger::DEBUG : Logger::INFO
          logger.formatter = proc do |_severity, datetime, _progname, msg|
            "#{datetime.strftime('%Y-%m-%d %H:%M:%S')} - #{msg}\n"
          end
        end
      end

      attr_accessor :logger

      def env
        ENV.fetch('RAILS_ENV') || ENV.fetch('RACK_ENV', 'development')
      end

      def root
        (defined?(RAILS_ROOT) && RAILS_ROOT) || (defined?(Rails) && Rails.root) || ENV.fetch('RAILS_ROOT')
      end
    end
  end
end
