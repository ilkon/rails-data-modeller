# frozen_string_literal: true

module DataModeller
  module Configurators
    class Controller
      class << self
        def config(filename, model_config)
          config = YAML.load_file(filename)
          return nil unless config.is_a?(Hash)

          config.deep_symbolize_keys!

          decompose_actions(config)
          update_sections(config, model_config)

          config
        end

        private

        def decompose_actions(config)
          return unless config[:actions] == 'crud'

          config[:actions] = %i[index show new edit create update destroy].each_with_object({}) do |action, hash|
            hash[action] = {}
          end
        end

        def update_sections(config, model_config)
          %i[attributes properties associations].each do |section|
            next if model_config[section].blank?

            config[section] = model_config[section].clone
          end
        end
      end
    end
  end
end
