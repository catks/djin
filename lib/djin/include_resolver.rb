# frozen_string_literal: true

module Djin
  class IncludeResolver
    using ObjectExtensions
    using HashExtensions

    def initialize(base_directory: '.', remote_directory: '~/.djin/remote', entity_class: Djin::IncludeConfig)
      # TODO: Use chain of responsability
      @base_directory = Pathname.new(base_directory)
      @remote_directory = Pathname.new(remote_directory)
      @entity_class = entity_class
    end

    def call(params)
      include_config_params = remote_handler(params)
      include_config_params ||= local_handler(params)

      build_entity(include_config_params)
    end

    private

    def remote_handler(params)
      return if params['git'].blank?

      version = params['version'] || 'master'
      # TODO: Extract RemoteConfig git_folder in IncludeConfig to another place and use it here
      # Maybe create a optional git_folder attribute and fill it in here?
      git_folder = "#{params['git'].split('/').last.chomp('.git')}@#{version}"

      # TODO: Use RemoteConfigRepository
      remote_file = @remote_directory.join(git_folder).join(params['file']).expand_path

      missing = !remote_file.exist?

      params.merge(missing: missing, file: remote_file.to_s, base_directory: @remote_directory.expand_path.to_s)
    end

    def local_handler(params)
      # TODO: Mark not existing files as missing and handle all the missing files
      missing = !@base_directory.join(params['file']).exist?
      params.merge(missing: missing, base_directory: @base_directory.expand_path.to_s)
    end

    def build_entity(params)
      @entity_class.new(**params.symbolize_keys)
    end
  end
end
