# frozen_string_literal: true

module Djin
  class Interpreter
    class DockerComposeCommandBuilder < BaseCommandBuilder
      def call(params, **_)
        service = params['service']

        compose_options = params['options']

        run_command, run_options = build_run_params(params['run'])

        [%(docker-compose #{compose_options} run #{run_options} #{service} sh -c "#{run_command}").squeeze(' '), nil]
      end
    end
  end
end
