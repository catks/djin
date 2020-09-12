# frozen_string_literal: true

module Djin
  # TODO: Refactor this class to be the Interpreter
  #       class and use the current interpreter as
  #       a TaskLoader
  class ConfigLoader
    using Djin::HashExtensions
    RESERVED_WORDS = %w[djin_version variables tasks include].freeze

    def self.load!(template_file, runtime_config: {})
      new(template_file, runtime_config: runtime_config).load!
    end

    def initialize(template_file, runtime_config: {})
      @template_file = template_file
      @template_file_content = Djin.cache.fetch(template_file.realpath.to_s) { template_file.read }
      @runtime_config = runtime_config
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

    def version
      # TODO: Deprecates djin_version and use version instead
      @version || raw_djin_config['djin_version']
    end

    def variables
      @variables ||= included_variables.merge(raw_djin_config['variables']&.symbolize_keys || {})
    end

    def tasks
      included_tasks.merge(rendered_djin_config['tasks'] || legacy_tasks)
    end

    def raw_tasks
      included_raw_tasks.merge(raw_djin_config['tasks'] || legacy_raw_tasks)
    end

    def legacy_tasks
      warn '[DEPRECATED] Root tasks are deprecated and will be removed in Djin 1.0.0,' \
           ' put the tasks under \'tasks\' keyword'

      rendered_djin_config.except(*RESERVED_WORDS).reject { |task| task.start_with?('_') }
    end

    def legacy_raw_tasks
      raw_djin_config.except(*RESERVED_WORDS).reject { |task| task.start_with?('_') }
    end

    def included_variables
      return {} unless included_config

      included_config.variables
    end

    def included_tasks
      return {} unless included_config

      included_config.tasks
    end

    def included_raw_tasks
      return {} unless included_config

      included_config.raw_tasks
    end

    def included_config
      @included_config ||= raw_djin_config['include']&.map do |tasks_reference|
        external_config_file = Pathname.new(tasks_reference['file'])

        ConfigLoader.load!(external_config_file, runtime_config: tasks_reference['context'] || {})
      end&.reduce(:deep_merge)
    rescue Errno::ENOENT => e
      raise Interpreter::InvalidConfigFileError, e.message
    end

    def args
      index = ARGV.index('--')

      return [] unless index

      ARGV.slice((index + 1)..ARGV.size)
    end

    def env
      @env ||= ENV.to_h.symbolize_keys
    end

    def raw_djin_config
      @raw_djin_config ||= yaml_load(@template_file_content).deep_merge(@runtime_config)
    rescue Psych::SyntaxError => e
      raise Interpreter::InvalidConfigFileError, "File: #{@template_file.realpath}\n  #{e.message}"
    end

    def rendered_djin_config
      @rendered_djin_config ||= begin
                                  locals = env.merge(variables)

                                  rendered_yaml = Mustache.render(@template_file_content,
                                                                  args: args.join(' '),
                                                                  args?: args.any?,
                                                                  **locals)
                                  yaml_load(rendered_yaml).merge(@runtime_config)
                                end
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
