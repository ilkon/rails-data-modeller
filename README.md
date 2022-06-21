# Rails Data Modeller

**Rails-Data-Modeller** is a Ruby gem which generates Rails application components, such as models, migrations, controllers. The input data are set as YAML-files.

## Installation

The project can be installed as a gem, to provide its methods to another application. To do so just include the gem in the `Gemfile`:

```ruby
gem 'rails-data-modeller', git: 'http://github.com/ilkon/rails-data-modeller'
```

and run `bundle install`.

For handy access to gem's tasks add the following code at the end of project's `Rakefile`:

```ruby
require 'data_modeller'
require 'data_modeller/tasks'

::DataModeller::Config.setup_logger
```

That's it.

## Usage

To generate parts of a new Rails application run the following task:

```rake data_modeller:generate[source_path,dest_path]```

The task parameters are:

* `source_path` -- path to a folder with config-files. When omitted, default value is used: _./data/sample/input_.
* `dest_path` -- path to a folder with a new Rails application where generated files will be written to. Default value: _./tmp_.

The generated files may require some extra config-files or concerns that should be present in the target application. To copy them simply run the task:
 
```rake data_modeller:export[dest_path]```

The task parameter `dest_path` has the same meaning as for previous task.

## Standalone application

The project can be used as a standalone application. Just fetch it by `git clone` command and run `bundle install` to make sure all required libraries for the project are installed.

Available rake tasks are the same as when installed as a gem.

## Development

### Code analyzer

The project uses Rubocop for static code analysis. It can run either from command line as `rubocop`, or as pre-commit git hook (recommended). When running as a pre-commit hook it checks added or modified files for coding standard compliance, and if problem found cancels the commit.

To install git-hook locally just launch the installation script:

```./script/install-git-hooks.sh```

## Testing

To test generators simply run the command

```rspec```

It reads config-files from `./data/sample/input` folder, generates application component files and compares them with files from `./data/sample/output` folder.
