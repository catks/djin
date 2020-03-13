module Djin
  class Task < Dry::Struct
    attribute :name, Types::String
    attribute :description, Types::String.optional.default(nil)
    attribute :build_command, Types::String.optional.default(nil)
    attribute :command, Types::String

    def ==(other)
      name == other.name &&
        command == other.command &&
        build_command == other.build_command
    end
  end
end
