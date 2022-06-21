# frozen_string_literal: true

module DataModeller
  module Generators
    class Base
      INDENT_CHAR = ' '
      INDENT_NUM = 2

      class << self
        def output_files(configs)
          generator = new(configs)
          generator.generate

          generator.files.transform_values { |content| content.is_a?(Array) ? content.map { |l| "#{l}\n" }.join : content }
        end
      end

      attr_reader :files

      def initialize(configs)
        @configs = configs
        @config = configs.first[1]
        @files = {}
        @resource_name = ActiveSupport::Inflector.singularize(configs.first[0])
        @resources_name = ActiveSupport::Inflector.pluralize(@resource_name)
      end

      private

      def init_new_file(filename)
        @current_file = @files[filename] = []
        @nesting = 0
      end

      def add_line(line = nil, deeper: false)
        if line.blank?
          @current_file << ''
        else
          if %w[end else elsif when].any? { |str| line.start_with?(str) }
            @nesting -= 1
            @current_file.pop while line == 'end' && @current_file.last.empty?
          end
          @current_file << "#{INDENT_CHAR * INDENT_NUM * @nesting}#{line}"
          @nesting += 1 if deeper
        end
      end

      def sanitized_value(value)
        str_value = value.to_s

        return str_value if %w[true false].include?(str_value) # Boolean

        return str_value if str_value.match?(/\A[+-]?\d+(?:\.\d*)?\z/) # Number

        return ":#{str_value}" if str_value.match?(/\A[a-z][a-z\d_]*\z/) # Symbol

        str_value
      end
    end
  end
end
