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
        raise VersionNotSupportedError, "Version #{version} is not supported, use #{Djin::VERSION} or higher" unless version_supported?(version)

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

        return build_docker_commands(docker_params, task_name: task_name) if docker_params
        build_docker_compose_commands(docker_compose_params) if docker_compose_params
      end

      def build_docker_commands(params, task_name:)
        current_folder_name = Pathname.getwd.basename.to_s
        image = params['image'] || "djin_#{current_folder_name}_#{task_name}"

        build_params = params['build']

        if build_params.is_a?(Hash)
          build_context = build_params['context']
          build_options = build_params['options']
        end

        build_context ||= build_params

        run_command, run_options = build_run_params(params['run'])

        command = %Q{docker run #{run_options} #{image} sh -c "#{run_command}"}.squeeze(' ')

        build_command = "docker build #{build_context} #{build_options} -t #{image}".squeeze(' ') if build_context

        [command, build_command]
      end

      def build_docker_compose_commands(params)
        service = params['service']

        compose_options = params['options']

        run_command, run_options = build_run_params(params['run'])

        [%Q{docker-compose #{compose_options} run #{run_options} #{service} sh -c "#{run_command}"}.squeeze(' '), nil]
      end

      def build_run_params(run_params)
        run_command = run_params

        if run_params.is_a?(Hash)
          run_command = run_params['commands']
          run_options = run_params['options']
        end

        run_command =  run_command.join(' && ') if run_command.is_a?(Array)

        [run_command, run_options]
      end

      def validate_version!(version)

      end

      def version_supported?(version)
        Vseries::SemanticVersion.new(Djin::VERSION) >= Vseries::SemanticVersion.new(version)
      end
    end
  end
end
