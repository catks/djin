# frozen_string_literal: true

module Djin
  class Interpreter
    using Djin::HashExtensions

    RESERVED_WORDS = %w[djin_version _default_options].freeze

    InvalidConfigurationError = Class.new(StandardError)
    MissingVersionError = Class.new(InvalidConfigurationError)
    VersionNotSupportedError = Class.new(InvalidConfigurationError)
    InvalidSyntaxError = Class.new(InvalidConfigurationError)

    class << self
      def load!(params)
        version = params['djin_version']
        raise MissingVersionError, 'Missing djin_version' unless version
        unless version_supported?(version)
          raise VersionNotSupportedError, "Version #{version} is not supported, use #{Djin::VERSION} or higher"
        end

        tasks_params = params.except(*RESERVED_WORDS).reject { |task| task.start_with?('_') }
        contract = TaskContract.new

        tasks_params.map do |task_name, options|
          result = contract.call(options)

          raise InvalidSyntaxError, { task_name.to_sym => result.errors.to_h } if result.failure?

          command, build_command = build_commands(options, task_name: task_name)

          task_params = {
            name: task_name,
            build_command: build_command,
            command: command,
            depends_on: options['depends_on']
          }.compact

          Djin::Task.new(**task_params)
        end
      end

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

      def version_supported?(version)
        Vseries::SemanticVersion.new(Djin::VERSION) >= Vseries::SemanticVersion.new(version)
      end
    end
  end
end
