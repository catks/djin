# frozen_string_literal: true

module Djin
  class CLI
    extend Dry::CLI::Registry

    def self.load_tasks!(tasks)
      tasks.each do |task|
        command = Class.new(Dry::CLI::Command) do
          desc "Runs: #{task.command}"

          define_method(:task) { task }

          def call(**)
            Executor.new.call(task)
          end
        end

        register task.name, command
      end
    end

    class Version < Dry::CLI::Command
      desc 'Prints Djin Version'

      def call(*)
        puts Djin::VERSION
      end
    end

    register '--version', Version, aliases: ['-v']
  end
end
