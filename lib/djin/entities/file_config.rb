# frozen_string_literal: true

module Djin
  class FileConfig < Dry::Struct
    attribute :djin_version, Types::String
    attribute :variables, Types::Hash.optional.default({}.freeze)
    attribute :tasks, Types::Hash
    attribute :raw_tasks, Types::Hash
    # TODO: Add env and args

    include Dry::Equalizer(:djin_version, :variables, :tasks, :raw_tasks)

    def version_supported?
      Vseries::SemanticVersion.new(Djin::VERSION) >= Vseries::SemanticVersion.new(djin_version)
    end
  end
end
