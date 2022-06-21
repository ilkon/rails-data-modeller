# frozen_string_literal: true

module Partitionable
  def self.included(base)
    base.class_eval do
      def self.partition_model(date, create: true)
        partition_suffix = date.strftime('%Y%m')

        return @partition_models[partition_suffix] if @partition_models && @partition_models[partition_suffix]

        schema = 'public'
        table = "#{table_name}_#{partition_suffix}"
        schema, table = table.split('.', 2) if table.include?('.')

        exists = connection.select_one("SELECT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = '#{schema}' AND tablename = '#{table}')")

        unless exists['exists'] == 't' || exists['exists'] == true
          return nil unless create

          connection.execute(
            "CREATE TABLE #{schema}.#{table}
                (CHECK (date >= DATE '#{date.beginning_of_month}' AND date < DATE '#{date.beginning_of_month.next_month}'))
                INHERITS (#{table_name})"
          )
          create_indexes(schema, table)
        end

        class_name = "#{name}_#{partition_suffix}"

        model_class = Class.new(self)

        model_class.define_singleton_method(:table_name) do
          "#{schema}.#{table}"
        end

        model_class.define_singleton_method(:name) do
          class_name
        end

        @partition_models ||= {}
        @partition_models[partition_suffix] = model_class
      end
    end
  end
end
