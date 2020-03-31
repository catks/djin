require "djin/version"
require "pathname"
require "yaml"
require "dry-struct"
require "dry-validation"
require "vseries"
require "dry/cli"
require "djin/extensions/hash_extensions"
require "djin/extensions/custom_predicates"
require "djin/entities/types"
require "djin/entities/task"
require "djin/interpreter"
require "djin/executor"
require "djin/cli"
require "djin/task_contract"
require "djin/repositories/task_repository"

module Djin
  class Error < StandardError; end
  # Your code goes here...

  def self.load_tasks!(path = Pathname.getwd.join('djin.yml'))
    abort 'Error: djin.yml not found' unless path.exist?

    djin_file = YAML.safe_load(path.read, [], [], true)
    tasks = Djin::Interpreter.load!(djin_file)

    @task_repository = TaskRepository.new(tasks)
    CLI.load_tasks!(tasks)

  rescue Djin::Interpreter::InvalidConfigurationError => ex
    abort(ex.message)
  end

  def self.tasks
    task_repository.all
  end

  def self.task_repository
    @task_repository ||= TaskRepository.new
  end
end

