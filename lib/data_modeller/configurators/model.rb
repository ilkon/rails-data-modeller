# frozen_string_literal: true

module DataModeller
  module Configurators
    class Model
      class << self
        def config(filename)
          config = YAML.load_file(filename)
          return nil unless config.is_a?(Hash)

          config.deep_symbolize_keys!

          decompose_custom_types(config)
          add_devise_attributes(config)
          convert_presence(config)
          add_indexes(config)
          add_associations(config)

          config
        end

        private

        def decompose_custom_types(config)
          config[:constants] ||= {}

          adding_attributes = {}
          removing_attributes = []

          config[:attributes].each do |attribute, props|
            case props[:type]
            when 'password'
              config[:attributes][attribute].merge!(
                original_type:        props[:type],
                type:                 'string',
                column_name:          "encrypted_#{attribute}",
                strip:                true,
                length:               { in: 'Attributor.password_length' },
                format:               {
                  with:    'Attributor.password_regexp',
                  message: 'should include a digit, uppercase and lowercase letter'
                },
                unless:               'proc { |a| a.password.nil? }',
                form_view_exclude:    true,
                list_view_exclude:    true,
                details_view_exclude: true
              )

            when 'email'
              config[:attributes][attribute].merge!(
                original_type: props[:type],
                type:          'string',
                strip:         true,
                downcase:      true,
                format:        {
                  with: 'Attributor.email_regexp'
                }
              )

            when 'phone'
              config[:attributes][attribute].merge!(
                original_type: props[:type],
                type:          'string',
                strip:         true,
                length:        { in: 'Attributor.phone_length' },
                format:        {
                  with: 'Attributor.phone_regexp'
                }
              )

            when 'money'
              config[:attributes][attribute].merge!(
                original_type:    props[:type],
                type:             'bigint',
                column_name:      "#{attribute}_cents",
                column_converter: 'money',
                format:           {
                  with:        'Attributor.money_regexp',
                  allow_blank: true
                }
              )

            when 'geolocation'
              removing_attributes << attribute

              adding_attributes["#{attribute}_latitude".to_sym] = props.merge(
                type:         'decimal',
                precision:    10,
                scale:        7,
                numericality: {
                  greater_than_or_equal_to: -90,
                  less_than_or_equal_to:    90
                }
              )
              adding_attributes["#{attribute}_longitude".to_sym] = props.merge(
                type:         'decimal',
                precision:    10,
                scale:        7,
                numericality: {
                  greater_than_or_equal_to: -180,
                  less_than_or_equal_to:    180
                }
              )

            when 'url'
              config[:attributes][attribute].merge!(
                original_type: props[:type],
                type:          'string',
                strip:         true,
                format:        {
                  with:        'Attributor.url_regexp',
                  allow_blank: true
                }
              )

            when 'enum'
              values = props[:values].each_with_index.each_with_object({}) { |(v, i), hash| hash[v] = i }

              config[:attributes][attribute].merge!(
                original_type: props[:type],
                type:          'integer',
                values:        values
              )

              config[:attributes][attribute][:default] = values[props[:default]] if props[:default].present?
            end
          end

          config[:attributes].merge!(adding_attributes)
          removing_attributes.each { |attr| config[:attributes].delete(attr) }
        end

        def add_devise_attributes(config)
          return if config.dig(:properties, :devise).blank?

          devise_properties = config[:properties][:devise]

          return unless devise_properties['database_authenticatable']

          config[:attributes].delete(:email)
          config[:attributes].delete(:password)
        end

        def convert_presence(config)
          config[:attributes].each do |_attribute, props|
            props[:null] = false if props[:presence].to_s == 'true'
          end
        end

        def add_indexes(config)
          config[:indexes] ||= {}

          config[:attributes].each do |attribute, props|
            next if props[:index].to_s == 'false'

            config[:attributes][attribute][:index] = false if props[:type] == 'reference'

            if props[:uniqueness].to_s == 'true'
              keys = index_keys(attribute, props)
              index_name = "\"\#{table_name}_#{keys.keys.join('_')}\"".to_sym

              config[:indexes][index_name] = {
                keys:   keys.values.flatten,
                unique: true
              }

            elsif props[:uniqueness].is_a?(Hash) && props[:uniqueness][:scope]
              keys = { props[:uniqueness][:scope] => props[:uniqueness][:scope] }.merge(index_keys(attribute, props))
              index_name = "\"\#{table_name}_#{keys.keys.join('_')}\"".to_sym

              config[:indexes][index_name] = {
                keys:   keys.values.flatten,
                unique: true
              }

            elsif props[:type] == 'reference'
              keys = index_keys(attribute, props)
              index_name = "\"\#{table_name}_#{keys.keys.join('_')}\"".to_sym

              config[:indexes][index_name] = {
                keys: keys.values.flatten
              }

            elsif props[:index].to_s == 'true'
              keys = index_keys(attribute, props)
              index_name = "\"\#{table_name}_#{keys.keys.join('_')}\"".to_sym

              config[:attributes][attribute].delete(:index)
              config[:indexes][index_name] = {
                keys: keys.values.flatten
              }
            end
          end

          return if config[:scopes].blank?

          config[:scopes].each do |_scope, props|
            keys = props.keys.sort
            index_name = "\"\#{table_name}_#{keys.join('_')}\"".to_sym
            config[:indexes][index_name] = {
              keys: keys
            }
          end
        end

        def index_keys(attribute, props)
          if props[:type] == 'reference'
            if props[:polymorphic].to_s == 'true'
              { attribute.to_s => %W[#{attribute}_type #{attribute}_id] }
            else
              { "#{attribute}_id" => %W[#{attribute}_id] }
            end
          else
            { attribute.to_s => [attribute.to_s] }
          end
        end

        def add_associations(config)
          config[:associations] ||= {}

          config[:attributes].each do |attribute, props|
            next unless props[:type] == 'reference'

            config[:associations][attribute] ||= {}
            config[:associations][attribute][:type] = 'belongs_to'
            config[:associations][attribute][:optional] = true unless props[:presence].to_s == 'true'
            config[:associations][attribute][:polymorphic] = true if props[:polymorphic].to_s == 'true'

            %i[class_name inverse_of counter_cache].each do |option|
              config[:associations][attribute][option] = props[option] if props[option]
            end
          end
        end
      end
    end
  end
end
