module Djin
  class CLI
    extend Dry::CLI::Registry

    def self.load_tasks!(tasks)
      tasks.each do |task|
        command = Class.new(Dry::CLI::Command) do
          desc "Runs: #{task.command}"

          define_method(:task) { task }

          def call(**options)
            Executor.new.call(task)
          end
        end

        register task.name, command
      end
    end
  end
end
