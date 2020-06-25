module Djin
  class Executor
    def initialize(task_repository: Djin.task_repository, args: [])
      @task_repository = task_repository
      @args = args
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

      run task.build_command if task.build_command
      run task.command if task.command
    end

    def run(command)
      command_with_args = Mustache.render(command,
                                          args: @args.join(' '),
                                          args?: @args.any?,
                                          **env)
      system command_with_args
    end

    def env
      @env = ENV.to_h.map {|k,v| [k.to_sym, v]}.to_h
    end
  end
end
