# frozen_string_literal: true

module Djin
  module ObjectExtensions
    refine Object do
      def presence(default = nil)
        present? ? self : default
      end

      def present?
        !blank?
      end

      def blank?
        return true unless self

        # TODO: Improve Validations
        return empty? if respond_to?(:empty?)

        false
      end
    end
  end
end
