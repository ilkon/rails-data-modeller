# frozen_string_literal: true

module DataModeller
  module Generators
    class Model < Base
      ASSOCIATION_OPTIONS = %i[
        through
        polymorphic
        as
        class_name
        join_table
        dependent
        primary_key
        foreign_key
        association_foreign_key
        inverse_of
        source
        source_type
        touch
        counter_cache
        validate
        autosave
        optional
      ].freeze

      VALIDATIONS = %i[
        acceptance
        confirmation
        presence
        absence
        uniqueness
        length
        inclusion
        exclusion
        format
        numericality
        allow_blank
        allow_nil
        if
        unless
      ].freeze

      def generate
        init_new_file("#{@resource_name}.rb")

        add_line('# frozen_string_literal: true')
        add_line

        add_line("class #{ActiveSupport::Inflector.camelize(@resource_name)} < ApplicationRecord", deeper: true)

        %i[includes constants specials associations validations callbacks scopes serializers accessors indexes].each do |section|
          content_count = @current_file.count
          send("generate_#{section}".to_sym)

          add_line if @current_file.count > content_count
        end

        add_line('end')
      end

      private

      def generate_includes
        return unless @config[:properties] && @config[:properties][:partitionable]

        add_line('include Partitionable')
      end

      def generate_constants
        return if @config[:constants].blank?

        @config[:constants].each do |constant, value|
          add_line("#{constant} = #{value.strip}.freeze")
        end
      end

      def generate_specials
        add_line("devise #{@config[:properties][:devise].strip}") if @config.dig(:properties, :devise)

        return if @config[:attributes].blank?

        @config[:attributes].each do |attribute, props|
          next unless props[:original_type] == 'enum'

          add_line("enum #{attribute}: { #{props[:values].map { |k, v| "#{k}: #{v}" }.join(', ')} }")
        end
      end

      def generate_associations
        return if @config[:associations].blank?

        belongs_to = @config[:associations].select { |_, props| props[:type] == 'belongs_to' }
        attached   = @config[:associations].select { |_, props| props[:type].end_with?('_attached') }
        others     = @config[:associations].reject { |association, _| belongs_to[association] || attached[association] }

        prepending_empty_lines = false
        [belongs_to, others, attached].each do |associations|
          next if associations.empty?

          add_line if prepending_empty_lines
          prepending_empty_lines = true

          associations.each do |association, props|
            type = props[:type]
            association_name = case type
                               when 'belongs_to', 'has_one', 'has_one_attached'
                                 ActiveSupport::Inflector.singularize(association)
                               when 'has_many', 'has_and_belongs_to_many', 'has_many_attached'
                                 ActiveSupport::Inflector.pluralize(association)
                               else
                                 raise "Unknown association type: #{type}"
                               end

            options = ASSOCIATION_OPTIONS.each_with_object({}) do |option, hash|
              next unless props[option]

              next if option == :counter_cache && type != 'belongs_to'

              hash[option] = sanitized_option_value(option, props[option])
            end

            if props[:type] == 'has_and_belongs_to_many' && props[:class_name].present? && props[:class_name].downcase != ActiveSupport::Inflector.singularize(association)
              options[:join_table] ||= "'#{[@resources_name, ActiveSupport::Inflector.pluralize(association)].sort.join('_')}'"
            end

            add_line("#{type} :#{association_name}#{options.present? ? ", #{options.map { |k, v| "#{k}: #{v}" }.join(', ')}" : ''}")
          end
        end
      end

      def generate_validations
        return if @config[:attributes].blank?

        @config[:attributes].each do |attribute, props|
          validations = VALIDATIONS.each_with_object({}) do |prop, hash|
            hash[prop] = send("#{prop}_validation".to_sym, props[prop]) if props[prop]
          end

          next if validations.empty?

          validation_rules = validations.map do |prop, rules|
            if rules.is_a?(Hash)
              "#{prop}: { #{rules.map { |k, v| "#{k}: #{v}" }.join(', ')} }"
            else
              "#{prop}: #{rules}"
            end
          end
          add_line("validates :#{attribute}, #{validation_rules.join(', ')}")
        end
      end

      def generate_callbacks
        return if @config[:attributes].blank?

        strip_attributes = []
        @config[:attributes].each do |attribute, props|
          add_line("before_validation { #{attribute}.downcase! if #{attribute}.present? }") if props[:downcase]

          strip_attributes << attribute if props[:strip]
        end

        return if strip_attributes.empty?

        add_line("strip_attributes #{strip_attributes.map { |attr| ":#{attr}" }.join(', ')}")
      end

      def generate_scopes
        if @config[:associations].present?
          @config[:associations].each do |association, props|
            type = props[:type]
            next if type.end_with?('_attached')

            association_name = case type
                               when 'belongs_to', 'has_one'
                                 ActiveSupport::Inflector.singularize(association)
                               when 'has_many', 'has_and_belongs_to_many'
                                 ActiveSupport::Inflector.pluralize(association)
                               else
                                 raise "Unknown association type: #{type}"
                               end
            table_name = ActiveSupport::Inflector.tableize(props[:class_name] || association_name)

            add_line("scope :with_#{association_name}, -> { includes(:#{association_name}).references(:#{table_name}) }")
          end
        end

        return if @config[:scopes].blank?

        @config[:scopes].each do |scope, props|
          add_line("scope :#{scope}, -> { where(#{props.map { |k, v| "#{k}: #{v}" }.join(', ')}) }")
        end
      end

      def generate_serializers
        return if @config[:attributes].blank?

        @config[:attributes].each do |attribute, props|
          next unless props[:type] == 'jsonb'

          add_line("serialize :#{attribute}, ObjectToJsonbSerializer")
        end
      end

      def generate_accessors
        return if @config[:attributes].blank?

        @config[:attributes].each do |attribute, props|
          next unless props[:column_name] && props[:column_name] != attribute

          case props[:column_converter]
          when 'money'
            add_line("def #{attribute}", deeper: true)
            add_line("@#{attribute} ||= #{props[:column_name]} && #{props[:column_name]} / 100.0")
            add_line('end')
            add_line
            add_line("def #{attribute}=(val)", deeper: true)
            add_line("self.#{props[:column_name]} = val.present? ? (val.to_f * 100.0).round : nil")
            add_line("@#{attribute} = val")
            add_line('end')
          else
            add_line("attr_accessor :#{attribute}")
          end
        end
      end

      def generate_indexes
        return if @config[:indexes].blank?

        return unless @config[:properties] && @config[:properties][:partitionable]

        add_line('class << self', deeper: true)
        add_line('def create_indexes(schema, table)', deeper: true)

        @config[:indexes].each do |index, value|
          name = index.to_s.sub('table_name', 'table').gsub('"', '')

          add_line("connection.execute(\"CREATE #{value[:unique] && 'UNIQUE '}INDEX #{name} ON \#{schema}.\#{table} (#{value[:keys].join(', ')})\")")
        end

        add_line('end')
        add_line('end')
      end

      def length_validation(prop)
        if prop.is_a?(Hash)
          %i[min max is in message wrong_length too_long too_short].each_with_object({}) do |option, hash|
            next unless prop[option]

            if (option == :min && prop[:max]) || (option == :max && prop[:min])
              hash[:in] = "#{prop[:min]}..#{prop[:max]}"
            elsif option == :max
              hash[:maximum] = prop[:max]
            elsif option == :min
              hash[:minimum] = prop[:min]
            else
              hash[option] = sanitized_option_value(option, prop[option])
            end
          end
        else
          prop.to_s
        end
      end

      def acceptance_validation(prop)
        generic_validation(%i[accept message], prop)
      end

      def confirmation_validation(prop)
        generic_validation(%i[case_sensitive message], prop)
      end

      def presence_validation(prop)
        generic_validation(%i[strict message], prop)
      end

      def absence_validation(prop)
        generic_validation(%i[message], prop)
      end

      def uniqueness_validation(prop)
        generic_validation(%i[scope case_sensitive message], prop)
      end

      def inclusion_validation(prop)
        generic_validation(%i[in within message], prop)
      end

      def exclusion_validation(prop)
        generic_validation(%i[in within message], prop)
      end

      def format_validation(prop)
        generic_validation(%i[with without message allow_blank], prop)
      end

      def numericality_validation(prop)
        generic_validation(%i[only_integer greater_than greater_than_or_equal_to equal_to less_than less_than_or_equal_to other_than odd even message], prop)
      end

      def allow_blank_validation(prop)
        prop.to_s
      end

      def allow_nil_validation(prop)
        prop.to_s
      end

      def if_validation(prop)
        prop.to_s
      end

      def unless_validation(prop)
        prop.to_s
      end

      def generic_validation(options, prop)
        if prop.is_a?(Hash)
          options.each_with_object({}) do |option, hash|
            next unless prop[option]

            hash[option] = sanitized_option_value(option, prop[option])
          end
        else
          prop.to_s
        end
      end

      def sanitized_option_value(option, value)
        str_value = value.to_s
        if %i[class_name join_table].include?(option)
          "'#{str_value}'"
        elsif %i[message wrong_length too_long too_short].include?(option)
          "'#{str_value.gsub("'", "\\\\'")}'"
        else
          sanitized_value(value)
        end
      end
    end
  end
end
