# frozen_string_literal: true

module Djin
  module IncludeConfig
    class Base < Dry::Struct
      attribute :file, Types::String
      attribute :context, Types::Hash.default({}.freeze)

      include Dry::Equalizer(:file, :context)

      def type
        raise NotImplementedError
      end
    end
  end
end
