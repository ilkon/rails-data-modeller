# frozen_string_literal: true

RSpec.describe DataModeller::Generators::Model, type: :model do
  describe '::output_files' do
    it 'generates model files' do
      model_config_files = File.join('.', 'data', 'sample', 'input', 'models', '*.yml')

      Dir.glob(model_config_files) do |config_file|
        config = DataModeller::Configurators::Model.config(config_file)
        next if config.blank?

        name = File.basename(config_file, '.*')

        described_class.output_files(name => config).each do |filename, content|
          file = File.join('.', 'data', 'sample', 'output', 'app', 'models', filename)
          expected_content = File.read(file)

          expect(content).to eql(expected_content)
        end
      end
    end
  end
end
