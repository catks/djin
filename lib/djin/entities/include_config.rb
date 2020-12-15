# frozen_string_literal: true

module Djin
  class IncludeConfig < Dry::Struct
    attribute :file, Types::String
    attribute :base_directory, Types::String
    attribute :context, Types::Hash.default({}.freeze)
    attribute :git, Types::String.optional.default(nil)
    attribute :version, Types::String.default('master')
    attribute :missing, Types::Bool.optional.default(nil)

    using Djin::ObjectExtensions

    include Dry::Equalizer(:git, :version, :file, :context)

    def type
      @type ||= git.present? ? :remote : :local
    end

    def present?
      !missing?
    end

    def missing?
      missing
    end

    def full_path
      base_directory_pathname.join(file).expand_path
    end

    def repository_fetched?
      @repository_fetched ||= base_directory_pathname.join(folder_name).exist?
    end

    # TODO: Rethink
    def folder_name
      @folder_name ||= "#{git.split('/').last.chomp('.git')}@#{version}"
    end

    private

    def base_directory_pathname
      @base_directory_pathname ||= Pathname.new(base_directory)
    end
  end
end
