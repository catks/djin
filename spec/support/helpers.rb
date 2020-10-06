# frozen_string_literal: true

module Helpers
  def disable_warnings
    @old_verbose = $VERBOSE
    $VERBOSE = nil

    yield

    $VERBOSE = @old_verbose
  end

  # TODO: Move run_command to be exclusive to feature specs
  def run_command(command, path: '.')
    @command_stdout, @command_stderr, @command_status = Open3.capture3("cd #{path} && #{command}")
  end

  attr_accessor :command_stdout, :command_stderr, :command_status
end
