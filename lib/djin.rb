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
require 'git'
require 'djin/extensions/hash_extensions'
require 'djin/extensions/object_extensions'
require 'djin/entities/types'
require 'djin/entities/task'
require 'djin/entities/include_config.rb'
require 'djin/entities/main_config'
require 'djin/interpreter/base_command_builder'
require 'djin/interpreter/docker_command_builder'
require 'djin/interpreter/docker_compose_command_builder'
require 'djin/interpreter/local_command_builder'
require 'djin/interpreter'
require 'djin/include_resolver'
require 'djin/config_loader'
require 'djin/executor'
require 'djin/root_cli_parser'
require 'djin/cli'
require 'djin/task_contract'
require 'djin/repositories/task_repository'
require 'djin/repositories/remote_config_repository'
require 'djin/memory_cache'

module Djin
  class Error < StandardError; end

  using Djin::ObjectExtensions

  class << self
    def load_tasks!(*file_paths)
      files = file_paths.presence || RootCliParser.parse![:files] || ['djin.yml']

      file_config = ConfigLoader.load_files!(*files)

      # TODO: Make all tasks be under 'tasks' key, passing only the tasks here
      tasks = Interpreter.load!(file_config)

      @task_repository = TaskRepository.new(tasks)

      remote_configs = file_config.include_configs.select { |f| f.type == :remote }
      @remote_config_repository = RemoteConfigRepository.new(remote_configs)

      CLI.load_tasks!(tasks)
    rescue Djin::Interpreter::InvalidConfigurationError => e
      error_name = e.class.name.split('::').last
      abort("[#{error_name}] #{e.message}")
    end

    def tasks
      task_repository.all
    end

    def task_repository
      @task_repository ||= TaskRepository.new
    end

    def remote_config_repository
      @remote_config_repository ||= RemoteConfigRepository.new
    end

    def cache
      @cache ||= MemoryCache.new
    end

    def root_path
      Pathname.new File.expand_path(__dir__ + '/..')
    end

    def warn(message, type: 'WARNING')
      stderr.puts "[#{type}] #{message}"
    end

    def warn_once(message, type: 'WARNING')
      return if warnings.include?(message)

      warn(message, type: type)

      warnings << message
    end

    def stderr
      $stderr
    end

    private

    def warnings
      @warnings ||= []
    end
  end
end
