# frozen_string_literal: true

module Djin
  # TODO: Refactor this class to be the Interpreter
  #       class and use the current interpreter as
  #       a TaskLoader
  class ConfigLoader
    using Djin::HashExtensions
    RESERVED_WORDS = %w[djin_version variables tasks].freeze

    def self.load!(template_file)
      new(template_file).load!
    end

    def initialize(template_file)
      @template_file = template_file
    end

    def load!
      validate_version!

      file_config
    end

    private

    def file_config
      FileConfig.new(
        djin_version: version,
        variables: variables,
        tasks: tasks,
        raw_tasks: raw_tasks
      )
    end

    def raw_djin_config
      @raw_djin_config ||= yaml_load(@template_file)
    rescue Psych::SyntaxError => e
      raise Interpreter::InvalidConfigFileError, e.message
    end

    def rendered_djin_config
      @rendered_djin_config ||= begin
                                  locals = env.merge(variables)

                                  rendered_yaml = Mustache.render(@template_file,
                                                                  args: args.join(' '),
                                                                  args?: args.any?,
                                                                  **locals)
                                  yaml_load(rendered_yaml)
                                end
    end

    def version
      # TODO: Deprecates djin_version and use version instead
      @version || raw_djin_config['djin_version']
    end

    def variables
      @variables ||= raw_djin_config['variables']&.symbolize_keys || {}
    end

    def tasks
      rendered_djin_config['tasks'] || legacy_tasks
    end

    def raw_tasks
      raw_djin_config['tasks'] || legacy_raw_tasks
    end

    def legacy_tasks
      warn '[DEPRECATED] Root tasks are deprecated and will be removed in Djin 1.0.0,' \
           ' put the tasks under \'tasks\' keyword'

      rendered_djin_config.except(*RESERVED_WORDS).reject { |task| task.start_with?('_') }
    end

    def legacy_raw_tasks
      raw_djin_config.except(*RESERVED_WORDS).reject { |task| task.start_with?('_') }
    end

    def args
      index = ARGV.index('--')

      return [] unless index

      ARGV.slice((index + 1)..ARGV.size)
    end

    def env
      @env ||= ENV.to_h.symbolize_keys
    end

    def yaml_load(text)
      YAML.safe_load(text, [], [], true)
    end

    def validate_version!
      raise Interpreter::MissingVersionError, 'Missing djin_version' unless version

      return if file_config.version_supported?

      raise Interpreter::VersionNotSupportedError, "Version #{version} is not supported, use #{Djin::VERSION} or higher"
    end
  end
end
