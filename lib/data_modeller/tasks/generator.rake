# frozen_string_literal: true

desc 'Generate Rails application based on set of config files'
task :generate, %i[source_path dest_path] do |task, args|
  ::DataModeller::Config.logger.info "#{'=' * 25} Task #{task.name} #{'=' * 25}"

  args.with_defaults(source_path: './data/sample/input', dest_path: './tmp')

  ::DataModeller.generate(args[:source_path], args[:dest_path])
end

desc 'Export Rails application component from data/export folder to target directory'
task :export, %i[dest_path] do |task, args|
  ::DataModeller::Config.logger.info "#{'=' * 25} Task #{task.name} #{'=' * 25}"

  args.with_defaults(dest_path: './tmp')

  export_path = Pathname.new(File.join(__dir__, '../../../data/export')).cleanpath
  sh "cp -R #{export_path}/. #{args[:dest_path]}/"
end
