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

      def deep_merge(other_hash)
        dup.deep_merge!(other_hash)
      end

      def deep_merge!(other_hash)
        merge!(other_hash) do |_, this_val, other_val|
          if this_val.is_a?(Hash) && other_val.is_a?(Hash)
            this_val.deep_merge(other_val)
          else
            other_val
          end
        end
      end
    end
  end
end
