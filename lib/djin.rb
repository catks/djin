require "djin/version"
require "pathname"
require "yaml"
require "dry-struct"
require "dry-validation"
require "dry/cli"
require "djin/extensions/hash_extensions"
require "djin/extensions/custom_predicates"
require "djin/entities/types"
require "djin/entities/task"
require "djin/interpreter"
require "djin/executor"
require "djin/cli"
require "djin/task_contract"

module Djin
  class Error < StandardError; end
  # Your code goes here...

  def self.load_tasks!(path = Pathname.getwd.join('djin.yml'))
    abort 'Error: djin.yml not found' unless path.exist?

    djin_file = YAML.load(path.read)
    @tasks = Djin::Interpreter.load!(djin_file)

    CLI.load_tasks!(@tasks)

  rescue Djin::Interpreter::InvalidSyntax => ex
    abort(ex.message)
  end

  def self.tasks
    @tasks || []
  end
end

