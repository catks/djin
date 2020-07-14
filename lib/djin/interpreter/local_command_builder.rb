module Djin
  class Interpreter
    class LocalCommandBuilder < BaseCommandBuilder
      def call(params, **_)
        build_run_params(params['run'])
      end
    end
  end
end
