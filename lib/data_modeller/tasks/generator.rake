# frozen_string_literal: true

desc 'Generate Rails application based on set of config files'
task :generate, %i[source_path dest_path] do |task, args|
  ::DataModeller::Config.logger.info "#{'=' * 25} Task #{task.name} #{'=' * 25}"

  args.with_defaults(source_path: './data/sample/input', dest_path: './tmp')

  ::DataModeller.generate(args[:source_path], args[:dest_path])
end
