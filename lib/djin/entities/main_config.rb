# frozen_string_literal: true

module Djin
  class MainConfig < Dry::Struct
    using HashExtensions

    attribute :djin_version, Types::String
    attribute :variables, Types::Hash.optional.default({}.freeze)
    attribute :tasks, Types::Hash
    attribute :raw_tasks, Types::Hash
    # TODO: Add env and args
    attribute :include_configs, Types::Array.of(Djin::IncludeConfig).default([].freeze)

    include Dry::Equalizer(:djin_version, :variables, :tasks, :raw_tasks)

    def version_supported?
      Vseries::SemanticVersion.new(Djin::VERSION) >= Vseries::SemanticVersion.new(djin_version)
    end

    def merge(file_config)
      merged_hash = to_h.merge(file_config.to_h)

      MainConfig.new(merged_hash)
    end

    def deep_merge(file_config)
      merged_hash = to_h.deep_merge(file_config.to_h)

      MainConfig.new(merged_hash)
    end
  end
end
