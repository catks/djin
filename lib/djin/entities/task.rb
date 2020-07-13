# frozen_string_literal: true

module Djin
  class Task < Dry::Struct
    attribute :name, Types::String
    attribute :description, Types::String.optional.default(nil)
    attribute :build_command, Types::String.optional.default(nil)
    attribute :command, Types::String.optional.default(nil)
    attribute :depends_on, Types::Array.of(Types::String).optional.default([].freeze)

    def ==(other)
      name == other.name &&
        command == other.command &&
        build_command == other.build_command
    end
  end
end
