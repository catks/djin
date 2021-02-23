# frozen_string_literal: true

module Djin
  class Executor
    def initialize(task_repository: Djin.task_repository)
      @task_repository = task_repository
    end

    def call(*tasks)
      tasks.each do |task|
        run_task(task)
      end
    end

    private

    def run_task(task)
      @task_repository.find_by_names(task.depends_on).each do |dependent_task|
        run_task dependent_task
      end

      run(task.build_command, task_name: task.name) if task.build_command
      run(task.command, task_name: task.name) if task.command
    end

    def run(command, task_name:)
      raise TaskError, "Task `#{task_name}` failed" unless system(command)
    end
  end
end
