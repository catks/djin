# frozen_string_literal: true

module Djin
  class Interpreter
    class DockerCommandBuilder < BaseCommandBuilder
      def call(params, task_name:)
        current_folder_name = Pathname.getwd.basename.to_s
        image = params['image'] || "djin_#{current_folder_name}_#{task_name}"

        build_params = params['build']

        if build_params.is_a?(Hash)
          build_context = build_params['context']
          build_options = build_params['options']
        end

        build_context ||= build_params

        run_command, run_options = build_run_params(params['run'])

        command = %(docker run #{run_options} #{image} sh -c "#{run_command}").squeeze(' ')

        build_command = "docker build #{build_context} #{build_options} -t #{image}".squeeze(' ') if build_context

        [command, build_command]
      end
    end
  end
end
