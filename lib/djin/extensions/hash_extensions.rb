# frozen_string_literal: true

module Djin
  module HashExtensions
    refine Hash do
      def except(*keys)
        reject { |key, _| keys.include?(key) }
      end
    end
  end
end
