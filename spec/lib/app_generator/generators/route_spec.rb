# frozen_string_literal: true

RSpec.describe DataModeller::Generators::Route, type: :model do
  describe '::output_files' do
    it 'generates routes files' do
      model_config_files = File.join('.', 'data', 'sample', 'input', 'models', '*.yml')
      controller_config_files = File.join('.', 'data', 'sample', 'input', 'controllers', '*.yml')

      model_configs = {}
      Dir.glob(model_config_files) do |config_file|
        config = DataModeller::Configurators::Model.config(config_file)
        next if config.blank?

        name = File.basename(config_file, '.*')
        model_configs[name] = config
      end

      controller_configs = {}
      Dir.glob(controller_config_files) do |config_file|
        name = File.basename(config_file, '.*')

        config = DataModeller::Configurators::Controller.config(config_file, model_configs[name])
        next if config.blank?

        controller_configs[name] = config
      end

      described_class.output_files(controller_configs).each do |filename, content|
        file = File.join('.', 'data', 'sample', 'output', 'config', filename)
        expected_content = File.read(file)

        expect(content).to eql(expected_content)
      end
    end
  end
end
