# frozen_string_literal: true

module Djin
  class Task < Dry::Struct
    attribute :name, Types::String
    attribute :description, Types::String.optional.default(nil)
    attribute :build_command, Types::String.optional.default(nil)
    attribute :command, Types::String.optional.default(nil)
    attribute :raw_command, Types::String.optional.default(nil)
    attribute :aliases, Types::Array.of(Types::String).optional.default([].freeze)
    attribute :depends_on, Types::Array.of(Types::String).optional.default([].freeze)

    include Dry::Equalizer(:name, :command, :build_command)
  end
end
