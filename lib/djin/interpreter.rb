# frozen_string_literal: true

module Djin
  # TODO: Refactor to TaskConfigLoader and make COnfigLoader to use this class
  class Interpreter
    using Djin::HashExtensions

    class << self
      # rubocop:disable Metrics/AbcSize
      def load!(file_config)
        # TODO: Move task validation to ConfigLoader and add variables/include validations
        task_contract = TaskContract.new

        file_config.tasks.map do |task_name, options|
          result = task_contract.call(options)

          raise InvalidSyntaxError, { task_name.to_sym => result.errors.to_h } if result.failure?

          command, build_command = build_commands(options, task_name: task_name)

          # FIXME(1): Handle dynamic named tasks, eg: {{namespace}}unit and remove condition
          if file_config.raw_tasks[task_name]
            raw_command, = build_commands(file_config.raw_tasks[task_name], task_name: task_name)
          end

          task_params = {
            name: task_name,
            build_command: build_command,
            # TODO: Remove `|| command` after FIXME(1)
            description: options['description'] || "Runs: #{raw_command || command}",
            command: command,
            raw_command: raw_command,
            aliases: options['aliases'],
            depends_on: options['depends_on']
          }.compact

          Djin::Task.new(**task_params)
        end
      end
      # rubocop:enable Metrics/AbcSize

      private

      def build_commands(params, task_name:)
        # Validate that only one ot the two is passed
        docker_params = params['docker']
        docker_compose_params = params['docker-compose']
        local_params = params['local']

        # TODO: Refactor to use chain of responsability
        return DockerCommandBuilder.call(docker_params, task_name: task_name) if docker_params
        return DockerComposeCommandBuilder.call(docker_compose_params) if docker_compose_params

        LocalCommandBuilder.call(local_params) if local_params
      end
    end
  end
end
