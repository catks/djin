# frozen_string_literal: true

module Djin
  module HashExtensions
    refine Hash do
      def except(*keys)
        reject { |key, _| keys.include?(key) }
      end

      def symbolize_keys
        map { |key, value| [key.to_sym, value] }.to_h
      end
    end
  end
end
