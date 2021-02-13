# frozen_string_literal: true

module Djin
  # TODO: Refactor this class to delegate the responsability of complex fields
  #       to a specific Loader (like include for IncludeConfigLoader),
  #       maybe renaming to RootConfigLoader

  # rubocop:disable Metrics/ClassLength
  class ConfigLoader
    using Djin::HashExtensions
    RESERVED_WORDS = %w[djin_version variables tasks include].freeze

    def self.load_files!(*files, context_config: {}, base_directory: '.')
      files.map do |file_path|
        ConfigLoader.load!(file_path, context_config: context_config, base_directory: base_directory)
      end&.reduce(:deep_merge)
    end

    def self.load!(template_file_path, context_config: {}, base_directory: '.')
      new(template_file_path, context_config: context_config, base_directory: base_directory).load!
    end

    def initialize(template_file_path, context_config: {}, base_directory: '.')
      @base_directory = Pathname.new(base_directory)
      @template_file = @base_directory.join(template_file_path)

      file_not_found!(@template_file) unless @template_file.exist?

      @template_file_content = Djin.cache.fetch(@template_file.realpath.to_s) { @template_file.read }
      @context_config = context_config
    end

    def load!
      validate_version!
      validate_missing_config!

      file_config
    end

    private

    def file_config
      MainConfig.new(
        djin_version: version,
        variables: variables,
        tasks: tasks,
        raw_tasks: raw_tasks,
        include_configs: @include_configs || []
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
      Djin.warn_once(
        'Root tasks are deprecated and will be removed in Djin 1.0.0,' \
        ' put the tasks under \'tasks\' keyword',
        type: 'DEPRECATED'
      )

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

    # TODO: Rename method
    def included_config
      @included_config ||= begin
                             present_include_configs&.map do |present_include|
                               ConfigLoader.load!(present_include.file, base_directory: @template_file.dirname,
                                                                        # TODO: Rename to context_config
                                                                        context_config: present_include.context)
                             end&.reduce(:deep_merge)
                           end
    end

    def present_include_configs
      include_configs&.select(&:present?)
    end

    def missing_include_configs
      include_configs&.select(&:missing?)
    end

    def include_configs
      @include_configs ||= Djin::IncludeConfigLoader.load!(raw_djin_config['include'],
                                                           base_directory: @template_file.dirname)
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
      @raw_djin_config ||= yaml_load(@template_file_content).deep_merge(@context_config)
    rescue Psych::SyntaxError => e
      raise InvalidConfigFileError, "File: #{@template_file.realpath}\n  #{e.message}"
    end

    def rendered_djin_config
      @rendered_djin_config ||= begin
                                  locals = env.merge(variables)

                                  rendered_yaml = Mustache.render(@template_file_content,
                                                                  args: args.join(' '),
                                                                  args?: args.any?,
                                                                  **locals)
                                  yaml_load(rendered_yaml).merge(@context_config)
                                end
    end

    def yaml_load(text)
      YAML.safe_load(text, [], [], true)
    end

    def validate_version!
      raise MissingVersionError, 'Missing djin_version' unless version

      return if file_config.version_supported?

      raise VersionNotSupportedError, "Version #{version} is not supported, use #{Djin::VERSION} or higher"
    end

    def validate_missing_config!
      missing_include_configs.each do |ic|
        file_not_found!(ic.full_path) if ic.type == :local

        missing_file_remote_error = "#{ic.git} exists but is missing %s," \
          'if the file exists in upstream run djin remote-config fetch to fix'

        file_not_found!(ic.full_path, missing_file_remote_error) if ic.type == :remote && ic.repository_fetched?

        if ic.type == :remote
          Djin.warn_once "Missing #{ic.git} with version '#{ic.version}', " \
            'run `djin remote-config fetch` to fetch the config'
        end
      end
    end

    def file_not_found!(filename, message = "File '%s' not found")
      raise FileNotFoundError, message % filename
    end
  end
  # rubocop:enable Metrics/ClassLength
end
