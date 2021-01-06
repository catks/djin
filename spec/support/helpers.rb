# frozen_string_literal: true

module Helpers
  def disable_warnings
    @old_verbose = $VERBOSE
    $VERBOSE = nil

    yield

    $VERBOSE = @old_verbose
  end

  # TODO: Move run_command to be exclusive to feature specs
  def run_command(command, path: '.', envs: {})
    envs_string = envs.map { |env, value| "#{env}='#{value}'" }.join(' ')

    command_string = [
      envs_string,
      "cd #{path}",
      command
    ].reject(&:empty?).join(' && ')

    @command_stdout, @command_stderr, @command_status = Open3.capture3(command_string)
  end

  def mock_command(*commands)
    commands.each do |command|
      main_command, *args = command.split(' ')
      original_command_path = `which #{main_command}`.chomp

      # Enable multiple subcommands
      mock_commands[main_command] = <<~COMMAND_SCRIPT
        #!/usr/bin/env ruby
        MAIN_COMMAND = '#{main_command}'
        ORIGINAL_COMMAND = '#{original_command_path}'
        MOCK_ARGS = #{args}

        #MOCK_ARGS.each do |mock_arg|
        #  exit 0 if ARGV.include?(mock_arg)
        #end

        #original_command_with_args = ([ORIGINAL_COMMAND] + ARGV).join(' ')
        #puts original_command_with_args
        #system(original_command_with_args)

        system(%Q{echo "#{command} $@" >> #{mock_commands_file};})
      COMMAND_SCRIPT
    end
  end

  # TODO: Extrack mock commands to a specific helper
  def setup_mock_commands
    mock_commands_path.mkpath
    ENV['PATH'] = "#{mock_commands_path}:#{ENV['PATH']}"

    mock_commands.each do |command_name, command_script|
      command_file = mock_commands_path.join(command_name)

      command_file.open('w+') do |file|
        file.write(command_script)
      end

      `chmod +wx #{command_file}`
    end
  end

  def executed_mocked_commands
    `touch #{mock_commands_file}`
    mock_commands_file.readlines
  end

  def clear_mocked_commands
    `rm -rf #{mock_commands_path}`
    # TODO: Remove path in $PATH
  end

  attr_reader :command_stdout, :command_stderr, :command_status

  private

  def mock_commands
    @mock_commands ||= {}
  end

  def mock_commands_file
    @mock_commands_file ||= mock_commands_path.join('_mock_commands')
  end

  def mock_commands_path
    @mock_commands_path ||= Djin.root_path.join('tmp/mock_commands')
  end
end
