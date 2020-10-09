# frozen_string_literal: true

require 'djin/version'
require 'pathname'
require 'yaml'
require 'dry-struct'
require 'dry-validation'
require 'vseries'
require 'dry/cli'
require 'mustache'
require 'optparse'
require 'djin/extensions/hash_extensions'
require 'djin/extensions/object_extensions'
require 'djin/entities/types'
require 'djin/entities/task'
require 'djin/entities/file_config'
require 'djin/interpreter/base_command_builder'
require 'djin/interpreter/docker_command_builder'
require 'djin/interpreter/docker_compose_command_builder'
require 'djin/interpreter/local_command_builder'
require 'djin/interpreter'
require 'djin/config_loader'
require 'djin/executor'
require 'djin/root_cli_parser'
require 'djin/cli'
require 'djin/task_contract'
require 'djin/repositories/task_repository'
require 'djin/memory_cache'

module Djin
  class Error < StandardError; end

  using Djin::ObjectExtensions

  def self.load_tasks!(*file_paths)
    files = file_paths.presence || RootCliParser.parse![:files] || ['djin.yml']

    file_config = ConfigLoader.load_files!(*files)

    # TODO: Make all tasks be under 'tasks' key, passing only the tasks here
    tasks = Interpreter.load!(file_config)

    @task_repository = TaskRepository.new(tasks)
    CLI.load_tasks!(tasks)
  rescue Djin::Interpreter::InvalidConfigurationError => e
    error_name = e.class.name.split('::').last
    abort("[#{error_name}] #{e.message}")
  end

  def self.tasks
    task_repository.all
  end

  def self.task_repository
    @task_repository ||= TaskRepository.new
  end

  def self.cache
    @cache ||= MemoryCache.new
  end

  def self.root_path
    Pathname.new File.expand_path(File.dirname(__FILE__) + '/..')
  end
end
