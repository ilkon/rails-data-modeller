# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'
require 'fileutils'

require_relative 'data_modeller/config'
require_relative 'data_modeller/configurators'
require_relative 'data_modeller/generators'

module DataModeller
  class << self
    def generate(source_path, dest_path)
      model_configs = {}
      model_config_files = File.join(source_path, 'models', '*.yml')
      Dir.glob(model_config_files) do |config_file|
        config = Configurators::Model.config(config_file)
        next if config.blank?

        name = File.basename(config_file, '.*')
        model_configs[name] = config
      end

      controller_configs = {}
      controller_config_files = File.join(source_path, 'controllers', '*.yml')
      Dir.glob(controller_config_files) do |config_file|
        name = File.basename(config_file, '.*')

        config = Configurators::Controller.config(config_file, model_configs[name])
        next if config.blank?

        controller_configs[name] = config
      end

      ordered_models = []
      models_config_file = File.join(source_path, 'models.yml')
      if File.exist?(models_config_file)
        models_config = YAML.load_file(models_config_file)
        ordered_models = models_config['models'] if models_config.is_a?(Hash) && models_config['models'].is_a?(Array)
      end

      generate_models(model_configs, dest_path)
      generate_migrations(model_configs, dest_path, ordered_models)
      generate_controllers(controller_configs, dest_path)
      generate_views(controller_configs, dest_path)
      generate_layout(controller_configs, dest_path)
      generate_routes(controller_configs, dest_path)
    end

    private

    def generate_models(configs, dest_path)
      configs.each do |name, config|
        Generators::Model.output_files(name => config).each do |filename, content|
          file = File.join(dest_path, 'app', 'models', filename)
          directory = File.dirname(file)
          FileUtils.mkdir_p(directory) unless File.directory?(directory)

          File.write(file, content)

          Config.logger.info "Model file #{file} generated"
        end
      end
    end

    def generate_migrations(configs, dest_path, ordered_models)
      models = ordered_models.present? ? ordered_models : ordered_models(configs)
      extra_index = models.count - 1
      extra_migrations = []

      configs.each do |name, config|
        Generators::Migration.output_files(name => config).each_with_index do |(filename, content), i|
          if i.zero?
            index = models.index(name)
            raise "Model name #{name} not found" if index.nil?
          else
            next if extra_migrations.include?(filename)

            extra_migrations << filename
            index = (extra_index += 1)
          end

          timestamp = Date.today.beginning_of_year + (index + 1).minutes
          file = File.join(dest_path, 'db', 'migrate', "#{timestamp.strftime('%Y%m%d%H%M%S')}_#{filename}")
          directory = File.dirname(file)
          FileUtils.mkdir_p(directory) unless File.directory?(directory)

          File.write(file, content)

          Config.logger.info "Migration file #{file} generated"
        end
      end
    end

    def generate_controllers(configs, dest_path)
      configs.each do |name, config|
        Generators::Controller.output_files(name => config).each do |filename, content|
          file = File.join(dest_path, 'app', 'controllers', filename)
          directory = File.dirname(file)
          FileUtils.mkdir_p(directory) unless File.directory?(directory)

          File.write(file, content)

          Config.logger.info "Controller file #{file} generated"
        end
      end
    end

    def generate_views(configs, dest_path)
      configs.each do |name, config|
        Generators::View.output_files(name => config).each do |filename, content|
          file = File.join(dest_path, 'app', 'views', filename)
          directory = File.dirname(file)
          FileUtils.mkdir_p(directory) unless File.directory?(directory)

          File.write(file, content)

          Config.logger.info "View file #{file} generated"
        end
      end
    end

    def generate_layout(configs, dest_path)
      return if configs.empty?

      Generators::Layout.output_files(configs).each do |filename, content|
        file = File.join(dest_path, 'app', 'views', filename)
        directory = File.dirname(file)
        FileUtils.mkdir_p(directory) unless File.directory?(directory)

        File.write(file, content)

        Config.logger.info "Layout file #{file} generated"
      end
    end

    def generate_routes(configs, dest_path)
      return if configs.empty?

      Generators::Route.output_files(configs).each do |filename, content|
        file = File.join(dest_path, 'config', filename)
        directory = File.dirname(file)
        FileUtils.mkdir_p(directory) unless File.directory?(directory)

        if File.exist?(file)
          new_routes_part = content.match(/# Data Modeller: begin.+# Data Modeller: end/m)
          if new_routes_part
            old_content = File.read(file)
            old_routes_part = old_content.match(/# Data Modeller: begin.+# Data Modeller: end/m)
            content = if old_routes_part
                        old_content.sub(old_routes_part[0], new_routes_part[0])
                      else
                        old_content.sub(/(end\n)\z/m, "  #{new_routes_part[0]}\nend\n")
                      end
          end
        end

        File.write(file, content)

        Config.logger.info "Route file #{file} saved"
      end
    end

    def ordered_models(configs)
      dependencies = {}
      configs.each do |name, config|
        dependencies[name] ||= []

        next if config[:attributes].blank?

        config[:attributes].each do |attribute, props|
          dependencies[name] << attribute.to_s if props[:type] == 'reference' && props[:foreign_key].present?
        end
      end

      ordered_models = []
      models = configs.keys

      until models.empty?
        model = models.pop
        ordered_models += (order_models(model, dependencies) - ordered_models) unless ordered_models.include?(model)
      end

      ordered_models
    end

    def order_models(model, dependencies)
      return [model] if dependencies[model].blank?

      models = []
      dependencies[model].each do |master|
        models += order_models(master, dependencies)
      end
      models << model

      models
    end
  end
end
