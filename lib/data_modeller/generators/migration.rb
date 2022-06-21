# frozen_string_literal: true

module DataModeller
  module Generators
    class Migration < Base
      OPTIONS = %i[
        null
        default
        index
        foreign_key
        precision
        scale
        polymorphic
      ].freeze

      def generate
        basename = "create_#{@resources_name}"
        init_new_file("#{basename}.rb")

        add_line('# frozen_string_literal: true')
        add_line

        version = defined?(ActiveRecord) ? "#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}" : '6.0'
        add_line("class #{ActiveSupport::Inflector.camelize(basename)} < ActiveRecord::Migration[#{version}]", deeper: true)

        generate_migration_method

        add_line('end')

        generate_join_tables
      end

      private

      def generate_migration_method
        table_name = ActiveSupport::Inflector.pluralize(@resource_name)

        properties = @config[:properties] || {}

        add_line('def change', deeper: true)
        add_line("table_name = '#{table_name}'")
        add_line

        options = %i[id].each_with_object({}) do |option, hash|
          next unless properties.key?(option)

          hash[option] = sanitized_option_value(option, properties[option])
          hash[:force] = 'true' if option == :id && hash[option].to_s == 'false'
        end

        options_str = options.present? ? ", #{options.map { |k, v| "#{k}: #{v}" }.join(', ')}" : ''

        add_line("create_table table_name#{options_str} do |t|", deeper: true)

        generate_columns
        add_line

        generate_devise_columns

        add_line('t.timestamps') if properties[:timestamps]

        add_line('end')
        add_line

        generate_indexes
        generate_devise_indexes

        add_line('end')
      end

      def generate_columns
        if @config[:attributes].present?
          @config[:attributes].each do |attribute, props|
            column_name = props[:column_name] || attribute
            type = props[:type] == 'reference' ? 'references' : props[:type]

            options = OPTIONS.each_with_object({}) do |prop, hash|
              hash[prop] = send("#{prop}_option".to_sym, props[prop]) if props.key?(prop)
            end

            option_rules = options.map do |prop, rules|
              if rules.is_a?(Hash)
                "#{prop}: { #{rules.map { |k, v| "#{k}: #{v}" }.join(', ')} }"
              else
                "#{prop}: #{rules}"
              end
            end

            if type == 'references' && props[:id]
              option_rules ||= []
              option_rules.unshift("type: :#{props[:id]}")
            end

            add_line("t.#{type} :#{column_name}#{option_rules.present? ? ", #{option_rules.join(', ')}" : ''}")
          end
        end

        return if @config[:associations].blank?

        @config[:associations].each do |association, props|
          next unless props[:counter_cache].present? && props[:type] != 'belongs_to'

          column_name = if props[:counter_cache].to_s == 'true'
                          association_name = ActiveSupport::Inflector.pluralize(association)
                          table_name = ActiveSupport::Inflector.tableize(props[:class_name] || association_name)
                          "#{table_name}_count"
                        else
                          props[:counter_cache].to_s
                        end

          add_line("t.integer :#{column_name}, default: 0")
        end
      end

      def generate_devise_columns
        return if @config.dig(:properties, :devise).blank?

        devise_properties = @config[:properties][:devise]

        if devise_properties['database_authenticatable']
          add_line("t.string :email, null: false, default: ''")
          add_line("t.string :encrypted_password, null: false, default: ''")
          add_line
        end

        if devise_properties['recoverable']
          add_line('t.string :reset_password_token')
          add_line('t.datetime :reset_password_sent_at')
          add_line
        end

        if devise_properties['rememberable']
          add_line('t.datetime :remember_created_at')
          add_line
        end

        if devise_properties['trackable']
          add_line('t.integer :sign_in_count, default: 0, null: false')
          add_line('t.datetime :current_sign_in_at')
          add_line('t.datetime :last_sign_in_at')
          add_line('t.inet :current_sign_in_ip')
          add_line('t.inet :last_sign_in_ip')
          add_line
        end

        if devise_properties['confirmable']
          add_line('t.string :confirmation_token')
          add_line('t.datetime :confirmed_at')
          add_line('t.datetime :confirmation_sent_at')
          add_line('t.string :unconfirmed_email # Only if using reconfirmable')
          add_line
        end

        if devise_properties['lockable']
          add_line('t.integer :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts')
          add_line('t.string :unlock_token # Only if unlock strategy is :email or :both')
          add_line('t.datetime :locked_at')
          add_line
        end

        return unless devise_properties['invitable']

        add_line('t.string :invitation_token')
        add_line('t.datetime :invitation_created_at')
        add_line('t.datetime :invitation_sent_at')
        add_line('t.datetime :invitation_accepted_at')
        add_line('t.integer :invitation_limit')
        add_line('t.references :invited_by, polymorphic: true')
        add_line('t.integer :invitations_count, default: 0')
        add_line
      end

      def null_option(prop)
        prop.to_s
      end

      def default_option(prop)
        str_prop = prop.to_s

        return str_prop if %w[true false].include?(str_prop) # Boolean

        return str_prop if str_prop.match?(/\A[+-]?\d+(?:\.\d*)?\z/) # Number

        return str_prop if str_prop.match?(/\A\[\]|{}\z/) # Empty Array or Hash

        "'#{str_prop}'"
      end

      def precision_option(prop)
        prop.to_s
      end

      def scale_option(prop)
        prop.to_s
      end

      def polymorphic_option(prop)
        prop.to_s
      end

      def index_option(prop)
        generic_option(%i[unique name], prop)
      end

      def foreign_key_option(prop)
        generic_option(%i[to_table on_delete name], prop)
      end

      def generic_option(options, prop)
        if prop.is_a?(Hash)
          options.each_with_object({}) do |option, hash|
            next unless prop[option]

            hash[option] = sanitized_option_value(option, prop[option])
          end
        else
          prop.to_s
        end
      end

      def generate_indexes
        return if @config[:indexes].blank?

        return if @config[:properties] && @config[:properties][:partitionable]

        @config[:indexes].each do |index, value|
          options = value.dup
          options[:name] = index
          keys = options.delete(:keys)
          key_str = keys.count == 1 ? ":#{keys.first}" : "%i[#{keys.join(' ')}]"
          add_line("add_index table_name, #{key_str}, #{options.map { |k, v| "#{k}: #{v}" }.join(', ')}")
        end
      end

      def generate_devise_indexes
        return if @config.dig(:properties, :devise).blank?

        devise_properties = @config[:properties][:devise]

        add_line("add_index table_name, :email, unique: true, name: \"\#{table_name}_email\"") if devise_properties['database_authenticatable']
        add_line("add_index table_name, :reset_password_token, unique: true, name: \"\#{table_name}_reset_password_token\"") if devise_properties['recoverable']
        add_line("add_index table_name, :confirmation_token, unique: true, name: \"\#{table_name}_confirmation_token\"") if devise_properties['confirmable']
        add_line("add_index table_name, :unlock_token, unique: true, name: \"\#{table_name}_unlock_token\"") if devise_properties['lockable']
        add_line("add_index table_name, :invitation_token, unique: true, name: \"\#{table_name}_invitation_token\"") if devise_properties['invitable']
      end

      def sanitized_option_value(_option, value)
        sanitized_value(value)
      end

      def generate_join_tables
        return if @config[:associations].blank?

        @config[:associations].each do |association, props|
          next unless props[:type] == 'has_and_belongs_to_many'

          associations_name = ActiveSupport::Inflector.pluralize(association)
          association_name = ActiveSupport::Inflector.singularize(association)
          attribute_name = props[:class_name].try(:downcase) || association_name

          table_name = [@resources_name, associations_name].sort.join('_')
          basename = "create_#{table_name}"
          init_new_file("#{basename}.rb")

          add_line('# frozen_string_literal: true')
          add_line

          version = defined?(ActiveRecord) ? "#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}" : '6.0'
          add_line("class #{ActiveSupport::Inflector.camelize(basename)} < ActiveRecord::Migration[#{version}]", deeper: true)

          add_line('def change', deeper: true)
          add_line("table_name = '#{table_name}'")
          add_line

          add_line('create_table table_name, id: false do |t|', deeper: true)
          [attribute_name, @resource_name].sort.each do |name|
            add_line("t.references :#{name}, index: false")
          end
          add_line('end')
          add_line

          [attribute_name, @resource_name].sort.each do |name|
            add_line("add_index table_name, :#{name}_id, name: \"\#{table_name}_#{name}\"")
          end

          add_line('end')
          add_line('end')
        end
      end
    end
  end
end
