# frozen_string_literal: true

require 'djin/version'
require 'pathname'
require 'yaml'
require 'dry-struct'
require 'dry-validation'
require 'vseries'
require 'dry/cli'
require 'mustache'
require 'djin/extensions/hash_extensions'
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
require 'djin/cli'
require 'djin/task_contract'
require 'djin/repositories/task_repository'

module Djin
  class Error < StandardError; end

  def self.load_tasks!(path = Pathname.getwd.join('djin.yml'))
    abort 'Error: djin.yml not found' unless path.exist?

    file_config = ConfigLoader.load!(path.read)

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
end
