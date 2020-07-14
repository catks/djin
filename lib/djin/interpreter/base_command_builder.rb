# frozen_string_literal: true

module Djin
  class Interpreter
    class BaseCommandBuilder
      def self.call(*options)
        new.call(*options)
      end

      private

      def build_run_params(run_params)
        run_command = run_params

        if run_params.is_a?(Hash)
          run_command = run_params['commands']
          run_options = run_params['options']
        end

        run_command = run_command.join(' && ') if run_command.is_a?(Array)

        [run_command, run_options]
      end
    end
  end
end
